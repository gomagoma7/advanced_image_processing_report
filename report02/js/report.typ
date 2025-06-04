#import "@preview/js:0.1.3": *
// or put your modified `js.typ` in the same folder and `#import "js.typ": *`

#show: js.with(
  lang: "ja",
  seriffont-cjk: "Hiragino Mincho ProN",
  sansfont: "Helvetica",
  sansfont-cjk: "Hiragino Kaku Gothic ProN",
  paper: "a4", // "a*", "b*", or (paperwidth, paperheight) e.g. (210mm, 297mm)
  fontsize: 10pt,
  baselineskip: auto,
  textwidth: auto,
  lines-per-page: auto,
  book: false, // or true
  cols: 1, // 1, 2, 3, ...
  non-cjk: regex("[\u0000-\u2023]"),  // or "latin-in-cjk" or any regex
  cjkheight: 0.88, // height of CJK in em
)

#maketitle(
  title: "画像工学特論 課題: 画像間の対応付け",
  authors: ("本田純也", "学籍番号: M233353"),
  date: "2025年06月04日",
  abstract: [
    【課題】OpenCV等を使い，与えられた2画像間の特徴点の対応付けを行うプログラムを作成し，実際に対応付けを行え．使用言語はC, C++, Python, Matlab 等なんでもよい．
    入力画像は自分自身で撮影したものを利用すること．
    最低でも3つ以上の異なるシーン，例えば，屋内，屋外，自然物，人工物，テクスチャの比較的多いシーン，テクスチャのほとんどないシーンなど，で画像を撮影すること．
    一つのシーンに対して，異なる位置，角度，ズームなどを変えながら複数の画像を撮影すること．
    対応付けにおける特徴量については，2つ以上の特徴量を使って対応付けを行うこと．
    それぞれのシーンおよびそれぞれの特徴量において，代表的な結果および考察を行うこと．
    - 使用した特徴量の簡単な説明（1ページ程度）．
    - レポート内の結果に対するすべての入力画像ペアとその簡単な説明．
    - 対応付けの結果と結果に対する考察．
    - 理解できたことのまとめ．
    - 作成したプログラム．
  ]
)

= 使用した特徴量

本レポートでは，5種類の特徴点検出アルゴリズム（SIFT，ORB，AKAZE，KAZE，BRISK）を用いて画像間の特徴点マッチング性能を評価した。
これらの手法はそれぞれ異なる特徴を持ち，用途に応じて使い分けられる。

== 使用した特徴量

== SIFT (Scale-Invariant Feature Transform)

- 特徴: スケール・回転不変性を持つ128次元記述子
- 仕組み: ガウシアンピラミッドとDoG（Difference of Gaussians）を用いた特徴点検出
- 利点: 高い識別性と安定性，照明変化に強い
- 欠点: 計算コストが高い

== BRISK (Binary Robust Invariant Scalable Keypoints)

- 特徴: 512ビットのバイナリ記述子
- 仕組み: 同心円サンプリングパターンによる高速記述子生成
- 利点: 高速処理，少ないメモリ使用量
- 欠点: SIFTと比べて識別性がやや劣る

== ORB (Oriented FAST and Rotated BRIEF)

- 特徴: 256ビットのバイナリ記述子
- 仕組み: FAST特徴点検出器とBRIEF記述子の組み合わせ
- 利点: 非常に高速,リアルタイム処理に適している
- 欠点: 特徴点数が限定的

== KAZE

- 特徴: 非線形スケール空間を使用した64次元記述子
- 仕組み: Perona-Malik拡散方程式による構造保存的な特徴抽出
- 利点: 高い精度，エッジ構造の保存
- 欠点: 計算時間が長い

== AKAZE (Accelerated-KAZE)

- 特徴: KAZEの高速化版，486ビットのバイナリ記述子
- 仕組み: Fast Explicit Diffusion（FED）による高速化
- 利点: KAZEの精度を保ちながら高速化
- 欠点: 実装が複雑

= マッチング手法

特徴点検出に加えて，2種類のマッチング手法を比較した。

== Brute-Force（BF）手法

- 全ての特徴点ペアで距離計算を行う全探索手法
- 正確だが計算時間が長い

== FLANN（Fast Library for Approximate Nearest Neighbors）手法

- 近似最近傍探索による高速マッチング
- 実用的な処理時間を実現

= 画像レジストレーション

画像レジストレーション（Image Registration）とは，異なる視点，異なる時間，異なるセンサーなどで取得された複数の画像を，共通の座標系に合わせて重ね合わせる処理である。
これは，医療画像診断，リモートセンシング，コンピュータビジョン，画像スティッチング（パノラマ画像作成）など，多岐にわたる分野で不可欠な技術である。

本実験では，特徴点マッチングとRANSACアルゴリズムを用いて得られたホモグラフィ行列（画像間の幾何学的変換を表す行列）を利用し，画像レジストレーションを実行した。
具体的には，ある画像（参照画像）の座標系に，別の画像（ターゲット画像）を変換して重ね合わせた。
この処理により，複数の画像から一貫した情報を取り出したり，画像の比較や統合を行ったりすることが可能となる。画像レジストレーションの成功は，マッチング結果の実用的な価値を評価する上での最終的な指標の一つである。

== 使用したアルゴリズム: RANSAC

RANSAC（Random Sample Consensus）は，データ中に多数の外れ値（ノイズや誤ったマッチ）が含まれる場合でも，ロバストにモデルを推定するための汎用的なアルゴリズムである。
特徴点マッチングにおいては，NNDRテストなどで得られたgood_matchesの中から，画像間の幾何学的変換（例えばホモグラフィ行列）を推定する際に利用される。

RANSACの基本的なプロセスは以下の通りである。

    1. ランダムサンプリング: good_matchesの中から，モデルを推定するために必要な最小限のデータ点（ホモグラフィの場合，最低4点）をランダムに選ぶ。
    2. モデル推定: 選ばれたデータ点を用いて，仮のモデル（ホモグラフィ行列）を推定する。
    3. インライア判定: 推定されたモデルに対し，残りの全てのデータ点（good_matches）がどの程度適合するかを評価する。モデルに適合するデータ点（許容範囲内の誤差を持つ点）をインライアと呼ぶ。
    4. モデルの選択: 最も多くのインライアを含むモデルを，最も信頼性の高いモデルとして選択する。

このプロセスを複数回繰り返すことで，外れ値の影響を最小限に抑え，真の幾何学的関係を正確に抽出することが可能となる。本実験では，画像レジストレーションの成功を判断する上で，RANSACによるインライアマッチの数が重要な基準となっている。

= 実験に用いた写真

== ナイアガラの滝

#figure(
  grid(
    columns: (2),
    image("../match_pics/niagara_a.jpeg", width: 50%),
    image("../match_pics/niagara_b.jpeg", width: 50%),
  ),
  caption: "niagara ：[自然の豊富なテクスチャ]"
)

この写真は，私がナイアガラの滝を見にいった時の写真である。
それぞれは，少し別角度で撮影している。
特徴となるようなテクスチャ(氷，太陽，滝など)が多いことから採用した。
配色としても比較的落ち着いている写真である。

== 金属の像

#figure(
  grid(
    columns: (2),
    image("../match_pics/iron-man_a.jpeg", width: 50%),
    image("../match_pics/iron-man_b.jpeg", width: 50%),
  ),
  caption: "iron-man ：[複雑なメタリック彫刻]"
)

この写真は，トロントのショッピングモールにある写真である。
金属で作られた人工物で，背景には，格子状の天井など，豊富な特徴が散りばめられていると思い採用した。
写真自体は，少し移動した場所から2枚撮影してある画像であるため，対応させるのが難しいと予想した。

== 鹿の像と建物

#figure(
  grid(
    columns: (2),
    image("../match_pics/white-deer_a.jpg", width: 70%),
    image("../match_pics/white-deer_b.jpg", width: 70%),
  ),
  caption: "white-deer ：[雪景色の中の鹿の像と建物]"
)

この写真は，雪の中のシカの像と建物が写っている写真である。
カナダのモントリオールで撮影した。
雪という白の広いテクスチャがあるほか，いくつかのオブジェクトがここに点在している。
後ろの建物を含め，特徴点がどこに向かうかを見たいと思い採用した。

== 雪の足跡

#figure(
  grid(
    columns: (2),
    image("../match_pics/snow-footprint_a.jpeg", width: 70%),
    image("../match_pics/snow-footprint_b.jpeg", width: 70%),
  ),
  caption: "snow-footprint：[雪の上の足跡とその周辺]"
)

この写真は，雪の足跡を撮影したものである。
他の写真と比べ，前後に動いて撮影してあるという違いがある。

== テーブルの食べ物

#figure(
  grid(
    columns: (2),
    image("../match_pics/delicious-food_a.jpeg", width: 70%),
    image("../match_pics/delicious-food_b.jpeg", width: 70%),
  ),
  caption: "delicious-food ：[テーブル上の食べ物]"
)

この写真は，テーブルの上に置いてある昼食の写真である。
食べ物の集まりのところは複数の複雑なテクスチャが集まっている。
また，撮影時は，別角度(上)から写真を撮っている。

== 研究室のテーブル

#figure(
  grid(
    columns: (2),
    image("../match_pics/lab-machine_a.jpeg", width: 70%),
    image("../match_pics/lab-machine_b.jpeg", width: 70%),
  ),
  caption: "lab-machine ：[プリンターなどがある机]"
)

この写真は，研究室内のテーブルの写真を撮ったものである。
ポットなど，色々なオブジェクトがある他，屋内であるという特徴がある。

== 研究室のゴミ箱

#figure(
  grid(
    columns: (2),
    image("../match_pics/lab-trash_a.jpeg", width: 70%),
    image("../match_pics/lab-trash_b.jpeg", width: 70%),
  ),
  caption: "lab-trash ：[ゴミ箱と新聞紙]"
)

この写真は，ラボ内のゴミ箱を撮った写真である。
2つの似たオブジェクトが並んでいた時にどのように検出されるかを見たかったため採用した。

= 評価手法

各組み合わせの性能を評価するために，以下の主要な指標を用いた。
これらの指標は，`experiments.py` 内の `perform_feature_matching()` で算出され，`analyze_results()` で集計・分析されたものである。

== 平均マッチ数 (good_matches)

これは，特徴点マッチングにおいて，「特徴点のマッチングが成功したと判断された点の平均数」を示す指標である。
具体的には，Nearest Neighbor Distance Ratio (NNDR) テストにおいて，最も近いマッチの距離が2番目に近いマッチの距離のratio_thresh（本実験では0.75）倍以下である場合を「良いマッチ（good_matches）」としてカウントした。
この指標は，各検出器とマッチング手法の組み合わせが，どれだけの数の対応点を生成できたかを示す量的な側面を評価する。

== 平均インライアマッチ数 (inlier_matches)

これは，good_matchesの中からRANSAC（Random Sample Consensus）アルゴリズムによって外れ値が除去され，最終的に正しい対応点として識別された点の平均数を示す指標である。
画像レジストレーション（位置合わせ）の精度と信頼性は，このインライアマッチ数に大きく依存する。
good_matchesが潜在的なマッチの総数を示すのに対し，inlier_matchesは真に信頼できるマッチの質と数を評価する上で極めて重要である。

== 平均処理時間

特徴点検出とマッチングにかかる時間の合計である。
本実験では，以下の3つの要素に分けて時間を計測し，その合計時間を評価した。

- 特徴点検出・記述時間 (detection_time): 各画像から特徴点を検出し，その記述子を計算するのに要した時間を示す。
- マッチング時間 (matching_time): 検出された特徴点記述子を用いて，2つの画像間の対応関係を探索するのに要した時間を示す。
- RANSAC時間 (ransac_time): マッチングされた点の中から，外れ値を除去し，ホモグラフィ行列をロバストに推定するのに要した時間を示す。

これらの時間の平均値は，各手法の実装効率と計算コストを評価する上で重要な指標となる。

== 成功率 (success_rate)

成功率は，全試行のうち，特徴点マッチングが成功し，かつ画像レジストレーション（位置合わせ）がRANSACによって正常に実行できた試行の割合を示す。
具体的には，以下の条件を全て満たした場合に「成功（success）」と判断した。

- good_matchesが4組以上存在すること。(RANSACの)
- RANSACによってホモグラフィ行列が計算され，かつ0より多くのインライアマッチ（inlier_matches）が存在すること。

この指標は，単なるマッチ数の多さだけでなく，そのマッチングが実際に画像の位置合わせという実用的なタスクに足る品質を持っていたか，すなわち手法の信頼性と実用性を総合的に評価する。

= 対応付けの結果と結果に対する考察

本実験では，7つの異なるシーンに対して5種類の特徴検出器と2種類のの組み合わせ（計70パターン）を評価した。
以下に主要な結果を示す。

== 検出器別の結果

#figure(
  grid(
    columns: (5),
    image("../feature_matching_results/niagara/niagara_SIFT_kp1.png", width: 90%),
    image("../feature_matching_results/niagara/niagara_BRISK_kp1.png", width: 90%),
    image("../feature_matching_results/niagara/niagara_ORB_kp1.png", width: 90%),
    image("../feature_matching_results/niagara/niagara_KAZE_kp1.png", width: 90%),
    image("../feature_matching_results/niagara/niagara_AKAZE_kp1.png", width: 90%)
  ),
  caption: ["SIFT",
    "BRISK",
    "ORB",
    "KAZE",
    "AKAZE"]
)

#figure(
  table(
    columns: 7,
    stroke: none,
    table.hline(),
    [*検出器*], [*平均マッチ数*], [*平均インライア数*], [*インライア率(%)*], [*平均処理時間(s)*], [*成功率(%)*], [*平均品質(%)*],
    table.hline(),
    [SIFT], [1220.6], [91.9], [7.5], [2.508], [100.0], [7.96],
    [BRISK], [1263.3], [104.8], [8.3], [1.226], [100.0], [6.87],
    [ORB], [47.3], [30.9], [65.3], [0.214], [92.9], [9.46],
    [KAZE], [1910.2], [132.4], [6.9], [8.807], [100.0], [15.79],
    [AKAZE], [777.2], [74.5], [9.6], [1.261], [100.0], [7.13],
    table.hline(),
  ),
  caption: [検出器別総合性能比較（修正版）]
)

上の表は，特徴量の検出器別の性能の比較結果である。
全てのシーンに対する平均を調べてわかったことを以下に示す。

- *SIFT*: 平均マッチ数（1220.6）と平均インライア数（1000.1）は高い値を示し，成功率は100.0%であった。平均処理時間はKAZEより速いが，BRISKやORBよりは遅かった。
- *BRISK*: 平均マッチ数（1263.3）はSIFTを上回ったが，平均インライア数（809.5）と平均品質（6.87%）はSIFTを下回った。平均処理時間（1.226秒）はAKAZEと同程度で高速であった。成功率は100.0%を維持した。
- *ORB*: 平均処理時間（0.214秒）は最も速かった。一方で，平均マッチ数（47.3）と平均インライア数（20.0）は最も低く，成功率も92.9%と他の検出器より低かった。
- *KAZE*: 平均マッチ数（1910.2）と平均品質（15.79%）において最高の性能を示し，平均インライア数も1213.4と最も多かった。しかし，平均処理時間（8.807秒）は最も長かった。
- *AKAZE*: 平均マッチ数（777.2）と平均インライア数（597.6）はBRISKより低いものの，平均処理時間（1.261秒）は高速であった。成功率は100.0%であった。

この結果から，特徴量検出とマッチ数の量的な差などが気になったため，検出効率についても追加で検証した。

=== 特徴点検出効率について

#figure(
  table(
    columns: 4,
    stroke: none,
    table.hline(),
    [*検出器*], [*平均特徴点数*], [*平均マッチ数*], [*検出効率(%)*],
    table.hline(),
    [KAZE], [17601], [1910.2], [*10.85*],
    [ORB], [500], [47.3], [*9.46*],
    [AKAZE], [16135], [777.2], [4.82],
    [SIFT], [30022], [1220.6], [4.07],
    [BRISK], [33063], [1263.3], [3.82],
    table.hline(),
  ),
  caption: [検出器別特徴点検出効率分析]
)

特徴点検出量やマッチ数の差について疑問に思ったため，検出の効率について調べると，マッチ数は単純に検出された特徴点数に比例しないことがわかった。

KAZEは，最も多くの平均合計キーポイント数（9880.5）を検出し，同時に最も多い平均マッチ数（1910.2）を記録した。
しかし，その「検出効率」は19.33%と，BRISKやAKAZEに比べて低い。

BRISK: 平均合計キーポイント数（3676.7）は中程度であったが，検出効率は34.36%と，検出器の中で最も高かった。
これは，BRISKが同心円サンプリングパターンによる高速なバイナリ記述子生成を行う際に，効率的に「マッチしやすい」特徴点を抽出できていることを示唆する。

ORB: 平均合計キーポイント数（980.0）が最も少ない検出器であり，平均マッチ数（47.3）も最も少なかった。検出効率も4.83%と，検出器の中で最も低い結果となった。

以上のことから，単に多くの特徴点を検出するだけでは，必ずしも多くのマッチや高いレジストレーション成功に繋がるわけではないことが示された。
むしろ，BRISKのように検出されるキーポイントの総数は中程度でも，その中から効率的に高品質なマッチを生成できる「検出効率」が高い検出器の方が，実用的な価値が高い場合があることを示唆する。
検出器の設計思想は，生成されるキーポイントの量だけでなく，その「マッチしやすさ」という質にも直接的に影響を与えると考える。

== マッチング手法別の性能比較

#figure(
  table(
    columns: 4,
    stroke: none,
    table.hline(),
    [*マッチング手法*], [*平均マッチング時間(s)*], [*平均マッチ数*], [*成功率(%)*],
    table.hline(),
    [FLANN], [0.441], [1087.2], [100.0],
    [BF], [5.646], [1000.2], [97.1],
    table.hline(),
  ),
  caption: [マッチング手法別性能比較]
)

次に，マッチング手法別の性能比較を行った。

FLANN手法は平均マッチング時間0.44秒に対し，Brute-Force手法は5.65秒を要し，12.8倍の処理時間差が生じた。

これは近似最近傍探索のマッチングの早さに置いて，優位的なものであると考える。

== シーン別難易度の分析

実験により，シーンの特性がマッチング性能に大きな影響を与えることがわかった。

最も容易なniagara（3783.3マッチ）と最も困難なdelicious-food（228.5マッチ）の間には約16倍の性能差が生じた。

容易なシーンとして，niagara（3783.3マッチ）が圧倒的な性能を示した。
これは自然の豊富なテクスチャ（滝，雲，氷など）が提供する多様で安定した特徴によるものであると考える。

中程度のシーンには，lab-trash（800.0マッチ），snow-footprint（790.2マッチ），iron-man（693.6マッチ），white-deer（522.3マッチ）が挙げられる。
これらは部分的に特徴的な領域を持つが，全体的には識別しやすい特徴が限定的である。

困難なシーンとして，lab-machine（488.2マッチ）とdelicious-food（228.5マッチ）が挙げられる。
前者は機械的な反復パターン，後者は異質なテクスチャの混在により，特徴点の一意性が低下していると考える。

ここでは，niagaraとdelicious-food，iron-manを示し，Appendixにその他の代表的なマッチング結果を添付する。

=== 比較的容易なシーン：niagara

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/niagara/niagara_SIFT_kp1.png", width: 50%),
    image("../feature_matching_results/niagara/niagara_SIFT_kp2.png", width: 50%),
    image("../feature_matching_results/niagara/niagara_SIFT_FLANN_matches.png"),
  ),
  caption: ["niagaraマッチング(検出:SIFT, マッチング:FLANN)"]
)

Niagara Fallsは平均3783.3マッチ，品質20.31%という比較的よい結果を示した。
この成功には以下の理由があると考える。

まず，自然のテクスチャが非常に豊富であることが挙げられる。水の流れ，雲の模様，氷の表面など，様々なパターンが画像全体に分布しており，特徴点検出器にとって理想的な環境を提供した。

次に，各部分の特徴がユニークであることも重要な要因である。滝の水流部分，岩の質感，空の雲の形状など，それぞれが他の部分と明確に区別できる特徴を持っている。
このため，誤った対応が生じにくく，高精度なマッチングが実現された。

さらに，構造が安定していることも挙げられる。
自然の風景は基本的に変形しない剛体として扱うことができ，視点変化による変形が予測可能である。
これにより，特徴点の対応付けが容易になったと考える。

=== 最も困難なシーン：delicious-food

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/delicious-food/delicious-food_SIFT_kp1.png", width: 80%),
    image("../feature_matching_results/delicious-food/delicious-food_SIFT_kp2.png", width: 80%),
    image("../feature_matching_results/delicious-food/delicious-food_SIFT_FLANN_matches.png"),
  ),
  caption: ["delicious-foodマッチング(検出:SIFT, マッチング:FLANN)"]
)

食べ物の画像は平均228.5マッチ，品質2.33%と予想以上に困難な結果となった。
この困難には複数の要因が重なっていると考える。

最大の問題は，様々な食材のテクスチャが混在していることである。
キャベツの繊維質な表面，トマトの滑らかな表面，肉の不規則な表面など，全く異なる特性を持つ材料が一つの画像内に共存している。
このため，統一的な特徴検出が困難になった。

また，同じような見た目の部分が多数存在することも問題である。
同じ食材内では似たようなテクスチャが繰り返し現れるため，どの特徴点がどこに対応するかを特定することが難しくなったと考える。

=== 特徴点の量 ≠ 性能のシーン: iron-man

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/iron-man/iron-man_SIFT_kp1.png", width: 50%),
    image("../feature_matching_results/iron-man/iron-man_SIFT_kp2.png", width: 50%),
    image("../feature_matching_results/iron-man/iron-man_SIFT_FLANN_matches.png"),
  ),
  caption: ["iron-manマッチング(検出:SIFT, マッチング:FLANN)"]
)

iron-manの写真での実験で，豊富な特徴点が検出されても必ずしも高い性能が得られるわけではないことを実証した。

反復的なメタリックパターンと複雑な3D形状変化により，特徴点は密集して検出されるものの，マッチング品質はわずか1.24%と非常に低い結果に終わった。
この発見は，特徴点の質がその量よりも重要であることを明確に示していると考える。

この困難の主な要因は，金属表面の反復パターンにある。
格子状の天井や金属彫刻の表面により，類似した見た目の特徴点が画像全体に多数出現する。このため，どの特徴点がどこに対応するかを特定することが困難になったと考える。

また，3D構造による視点変化の影響も大きい。平面的な画像とは異なり，立体的な彫刻では視点が少し変わるだけで特徴点の相対位置関係が大きく変化する。
さらに，金属表面の鏡面反射により，照明条件によって特徴の見え方が不安定になることも性能低下の一因である。

この結果から，単に多くの特徴点を検出するだけでは，必ずしも多くのマッチや高いレジストレーション成功に繋がるわけではないことが示された。
むしろ，検出される特徴点の「マッチしやすさ」という質的な側面が重要であることを示唆する。検出器の設計思想は，生成される特徴点の量だけでなく，その「マッチしやすさ」という質にも直接的に影響を与えると考える。

= 理解できたことまとめ

== 「特徴点の量 ≠ 性能」である。

iron-manの写真での実験で，豊富な特徴点が検出されても必ずしも高い性能が得られるわけではないことを実証した。
反復的なメタリックパターンと複雑な3D形状変化により，特徴点は密集して検出されるものの，マッチング品質はわずか1.24%と非常に低い結果に終わった。
この発見は，特徴点の質がその量よりも重要であることを明確に示していると考える。

== 特徴点マッチング手法

本実験を通じて，従来の特徴点マッチング手法の明確な以下のような限界も浮き彫りになった。

- 非剛体変形への対応不足: 食べ物のような柔らかい物体での性能が低いことから，従来手法が剛体変換を前提としていることが示された。
- 反復パターンでの困難: Iron Manのような反復的なパターンでは，特徴点の一意性を確保することが難しく，識別性能が低下する。
- 極端な条件での性能低下: 大きな視点変化や照明変化といった極端な条件下では，実用アプリケーションにおける制約となる性能低下が見られた。

== niagaraの精度

本実験を通じて，画像間の幾何学的関係の重要性を実感した。

特に，niagaraの写真は，遠距離撮影した画像のため，アフィン近似が有効でありそうである。

逆に，近距離や大きな視点変化がある場合は，透視投影の非線形性が顕著に現れ，従来手法の限界を実感した。

Factorization法で仮定される「すべての点が全画像で観測される」条件の厳しさを改めて理解した。

= Appendix

== 対応づけ結果(その他)

- SIFTの特徴量検出を行ってFLANNでマッチングした結果を以下に示す。

=== white-deer

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/white-deer/white-deer_SIFT_kp1.png", width: 50%),
    image("../feature_matching_results/white-deer/white-deer_SIFT_kp2.png", width: 50%),
    image("../feature_matching_results/white-deer/white-deer_SIFT_FLANN_matches.png"),
  ),
  caption: ["white-deer(検出:SIFT, マッチング:FLANN)"]
)

この写真は，雪景色の中の鹿の像と建物を撮影したものである。
雪の白い広範囲なテクスチャと建物の構造的な特徴により，中程度のマッチング性能（522.3マッチ）を示した。
建物の窓や柱などの人工的な構造は比較的安定した特徴を提供する一方，雪の表面は均一すぎるため特徴点が少なく，全体的にバランスの取れた結果となった。

=== snow-footprint

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/snow-footprint/snow-footprint_SIFT_kp1.png", width: 50%),
    image("../feature_matching_results/snow-footprint/snow-footprint_SIFT_kp2.png", width: 50%),
    image("../feature_matching_results/snow-footprint/snow-footprint_SIFT_FLANN_matches.png"),
  ),
  caption: ["snow-footprint(検出:SIFT, マッチング:FLANN)"]
)

雪の上の足跡とその周辺を撮影した写真である。
平均790.2マッチと比較的良好な結果を得た。
足跡による雪面の凹凸や，背景の建物構造が有効な特徴を提供したと考える。
また，この写真は他と異なり前後に移動して撮影されているため，視点変化による幾何学的変換がより複雑になった。

しかし，上方向に特徴点の対応がされていそうなことがわかる。

=== lab-machine

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/lab-machine/lab-machine_SIFT_kp1.png", width: 50%),
    image("../feature_matching_results/lab-machine/lab-machine_SIFT_kp2.png", width: 50%),
    image("../feature_matching_results/lab-machine/lab-machine_SIFT_FLANN_matches.png"),
  ),
  caption: ["lab-machine(検出:SIFT, マッチング:FLANN)"]
)

研究室内のテーブル上の機械を撮影した写真である。平均488.2マッチと比較的困難なシーンとなった。
プリンターや電子機器などの人工物には直線的な構造が多く，反復的なパターンが存在するため，特徴点の一意性が低下したと考える。
また，屋内での撮影のため照明条件が限定的で，コントラストが不十分な領域が存在することも性能低下の要因と思われる。

=== lab-trash

#figure(
  grid(
    columns: (3),
    image("../feature_matching_results/lab-trash/lab-trash_SIFT_kp1.png", width: 50%),
    image("../feature_matching_results/lab-trash/lab-trash_SIFT_kp2.png", width: 50%),
    image("../feature_matching_results/lab-trash/lab-trash_SIFT_FLANN_matches.png"),
  ),
  caption: ["lab-trash(検出:SIFT, マッチング:FLANN)"]
)

研究室内のゴミ箱を撮影した写真である。
平均800.0マッチと中程度の性能を示した。
2つの似たようなゴミ箱が並んでいることで，特徴点の対応付けにおいて興味深い課題を提示している。
同一物体が複数存在する場合の対応付けの難しさを示すと同時に，背景の壁や床などの安定した特徴により，ある程度のマッチングは成功した。
新聞紙に特徴が集まっていることも面白い結果である。

== Registration 結果まとめ

#grid(
  columns: (3),
  figure(
    image("../feature_matching_results/niagara/niagara_SIFT_FLANN_registration.png"),
    caption: [niagaraのもの。よく重ね合わされている。]
  ),
  figure(
    image("../feature_matching_results/delicious-food/delicious-food_SIFT_FLANN_registration.png"),
    caption: [delicious-foodはマッチングはうまくいっていなかったが，特徴がまとまっていたので，重ね合わせはうまくいっているように見える]
  ),
  figure(
    image("../feature_matching_results/iron-man/iron-man_SIFT_FLANN_registration.png"),
    caption: [iron-manは，特徴量は多かったものの，実際のregistrationはうまくいってなさそうである。]
  )
)

#figure(
  grid(
    columns: (2),
    image("../feature_matching_results/lab-trash/lab-trash_SIFT_FLANN_registration.png"),
    image("../feature_matching_results/lab-machine/lab-machine_SIFT_FLANN_registration.png"),
  ),
  caption: [平行な線の分だけズレる]
)

#figure(
  grid(
    columns: (2),
    image("../feature_matching_results/white-deer/white-deer_SIFT_FLANN_registration.png", width: 70%),
    image("../feature_matching_results/snow-footprint/snow-footprint_SIFT_FLANN_registration.png", width: 70%)
  ),
  caption: [うまくregistrationされていそう。特に，予想通り上方向にされている(右)]
)

== Code

- githubに全コードを挙げている。
  - https://https://github.com/gomagoma7/advanced_image_processing_report.git
  - /report02/

#figure(
  ```python
  def create_detector(detector_type):
    """Create feature detector"""
    detectors = {
        "SIFT": cv2.SIFT_create(),
        "ORB": cv2.ORB_create(),
        "AKAZE": cv2.AKAZE_create(),
        "KAZE": cv2.KAZE_create(),
        "BRISK": cv2.BRISK_create()
    }
    return detectors[detector_type]
  ```,
  caption: [create_detector()],
  kind: "code",
  supplement: [コード]
)

#figure(
  ```python
  def create_matcher(matcher_type, detector_type):
    """Create feature matcher"""
    if matcher_type == "BF":
        if detector_type in ["ORB", "BRISK"]:
            return cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)
        else:
            return cv2.BFMatcher(cv2.NORM_L2, crossCheck=False)
    else:  # FLANN
        if detector_type in ["SIFT", "AKAZE", "KAZE"]:
            index_params = dict(algorithm=1, trees=5)
            search_params = dict(checks=50)
            return cv2.FlannBasedMatcher(index_params, search_params)
        else:
            index_params = dict(algorithm=6, table_number=6, key_size=12, multi_probe_level=1)
            search_params = dict(checks=50)
            return cv2.FlannBasedMatcher(index_params, search_params)
  ```,
  caption: [create_matcher()],
  kind: "code",
  supplement: [コード]
)

#figure(
  ```python
  def prepare_descriptors(desc1, desc2, matcher_type, detector_type):
    """Prepare descriptors for FLANN if needed"""
    if matcher_type == "FLANN":
        if detector_type in ["SIFT", "AKAZE", "KAZE"]:
            desc1 = np.float32(desc1)
            desc2 = np.float32(desc2)
        else:
            desc1 = np.uint8(desc1)
            desc2 = np.uint8(desc2)
    return desc1, desc2
  ```,
  caption: [create_descriptor()],
  kind: "code",
  supplement: [コード]
)

#figure(
  ```python
  def perform_feature_matching(image1_path, image2_path, detector_type="SIFT", 
                            matcher_type="BF", ratio_thresh=0.75, output_dir=None):
    """Core feature matching function"""
    
    # Load images
    img1_color = cv2.imread(image1_path)
    img2_color = cv2.imread(image2_path)
    img1 = cv2.imread(image1_path, cv2.IMREAD_GRAYSCALE)
    img2 = cv2.imread(image2_path, cv2.IMREAD_GRAYSCALE)
    
    if img1 is None or img2 is None:
        return None
    
    # Feature detection
    detector = create_detector(detector_type)
    start_time = time.time()
    kp1, des1 = detector.detectAndCompute(img1, None)
    kp2, des2 = detector.detectAndCompute(img2, None)
    detection_time = time.time() - start_time
    
    if des1 is None or des2 is None or len(kp1) == 0 or len(kp2) == 0:
        return {
            "kp1_count": len(kp1) if kp1 else 0,
            "kp2_count": len(kp2) if kp2 else 0,
            "good_matches": 0, "detection_time": detection_time,
            "matching_time": 0, "ransac_time": 0, "inlier_matches": 0,
            "detector": detector_type, "matcher": matcher_type,
            "match_quality": 0.0, "status": "no_features"
        }
    
    # Feature matching
    des1, des2 = prepare_descriptors(des1, des2, matcher_type, detector_type)
    matcher = create_matcher(matcher_type, detector_type)
    
    start_time = time.time()
    matches = matcher.knnMatch(des1, des2, k=2)
    matching_time = time.time() - start_time
    
    # Ratio test
    good_matches = []
    if matches:
        for match_list in matches:
            if len(match_list) >= 2:
                m, n = match_list
                if m.distance < ratio_thresh * n.distance:
                    good_matches.append(m)
    
    match_quality = len(good_matches) / min(len(kp1), len(kp2)) * 100 if min(len(kp1), len(kp2)) > 0 else 0
    
    # Save visualizations
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        base_name = os.path.basename(image1_path).split('_')[0]
        
        # Keypoints
        img_kp1 = cv2.drawKeypoints(img1_color, kp1, None, color=(0, 255, 0))
        img_kp2 = cv2.drawKeypoints(img2_color, kp2, None, color=(0, 255, 0))
        cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_kp1.png", img_kp1)
        cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_kp2.png", img_kp2)
        
        # Matches
        img_matches = cv2.drawMatches(img1_color, kp1, img2_color, kp2, good_matches, None,
                                     flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)
        cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_{matcher_type}_matches.png", img_matches)
    
    # RANSAC and registration
    ransac_time = 0
    inlier_matches = 0
    registration_success = False
    
    if len(good_matches) > 4:
        src_pts = np.float32([kp1[m.queryIdx].pt for m in good_matches]).reshape(-1, 1, 2)
        dst_pts = np.float32([kp2[m.trainIdx].pt for m in good_matches]).reshape(-1, 1, 2)
        
        start_time = time.time()
        H, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)
        ransac_time = time.time() - start_time
        
        if mask is not None:
            inlier_matches = sum(mask.ravel())
        
        if H is not None and inlier_matches > 0:
            registration_success = True
            if output_dir:
                img1_warped = cv2.warpPerspective(img1_color, H, (img2.shape[1], img2.shape[0]))
                gray_warped = cv2.cvtColor(img1_warped, cv2.COLOR_BGR2GRAY)
                ret, mask_warped = cv2.threshold(gray_warped, 1, 255, cv2.THRESH_BINARY)
                mask_warped_inv = cv2.bitwise_not(mask_warped)
                img2_masked = cv2.bitwise_and(img2_color, img2_color, mask=mask_warped_inv)
                img_registered = cv2.add(img2_masked, img1_warped)
                cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_{matcher_type}_registration.png", 
                           img_registered)
    
    # Status
    if len(good_matches) == 0:
        status = "no_matches"
    elif len(good_matches) < 4:
        status = "insufficient_matches"
    elif not registration_success:
        status = "registration_failed"
    else:
        status = "success"
    
    return {
        "kp1_count": len(kp1), "kp2_count": len(kp2), "good_matches": len(good_matches),
        "detection_time": detection_time, "matching_time": matching_time, "ransac_time": ransac_time,
        "inlier_matches": inlier_matches, "detector": detector_type, "matcher": matcher_type,
        "match_quality": match_quality, "status": status,
        "image1_path": image1_path, "image2_path": image2_path
    }
  ```,
  caption: [perform_feature_matching()],
  kind: "code",
  supplement: [コード]
)

#figure(
  ```python
  def find_image_pairs(image_dir):
    """Find image pairs in directory"""
    image_files = []
    for root, _, files in os.walk(image_dir):
        for filename in files:
            if any(filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png']):
                image_files.append(os.path.join(root, filename))
    
    image_pairs = {}
    for filepath in image_files:
        filename = os.path.basename(filepath)
        base_name_parts = filename.rsplit('_', 1)
        if len(base_name_parts) == 2:
            base_name = base_name_parts[0]
            suffix_with_ext = base_name_parts[1]
            
            if base_name not in image_pairs:
                image_pairs[base_name] = {'a': None, 'b': None}
            
            if suffix_with_ext.lower().startswith('a.'):
                image_pairs[base_name]['a'] = filepath
            elif suffix_with_ext.lower().startswith('b.'):
                image_pairs[base_name]['b'] = filepath
    
    return {k: v for k, v in image_pairs.items() if v.get('a') and v.get('b')}
  ```,
  caption: [perform_feature_matching()],
  kind: "code",
  supplement: [コード]
)

#figure(
  ```python
  def analyze_results(results_list, output_dir):
    """Analyze and save results"""
    if not results_list:
        return
    
    valid_results = [r for r in results_list if r is not None]
    analysis_dir = os.path.join(output_dir, "analysis")
    os.makedirs(analysis_dir, exist_ok=True)
    
    # Save CSV
    with open(f"{analysis_dir}/detailed_results.csv", 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['base_name', 'detector', 'matcher', 'kp1_count', 'kp2_count',
                     'good_matches', 'inlier_matches', 'match_quality', 'detection_time',
                     'matching_time', 'ransac_time', 'status']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for result in valid_results:
            base_name = os.path.basename(result['image1_path']).split('_')[0]
            writer.writerow({
                'base_name': base_name, 'detector': result['detector'], 'matcher': result['matcher'],
                'kp1_count': result['kp1_count'], 'kp2_count': result['kp2_count'],
                'good_matches': result['good_matches'], 'inlier_matches': result['inlier_matches'],
                'match_quality': f"{result['match_quality']:.2f}",
                'detection_time': f"{result['detection_time']:.4f}",
                'matching_time': f"{result['matching_time']:.4f}",
                'ransac_time': f"{result['ransac_time']:.4f}",
                'status': result['status']
            })
    
    # Analyze by detector
    detector_analysis = {}
    matcher_analysis = {}
    
    for result in valid_results:
        detector = result['detector']
        matcher = result['matcher']
        
        if detector not in detector_analysis:
            detector_analysis[detector] = {
                'total_runs': 0, 'successful_runs': 0, 'total_matches': 0,
                'total_inliers': 0, 'total_detection_time': 0.0, 'avg_match_quality': 0.0
            }
        
        if matcher not in matcher_analysis:
            matcher_analysis[matcher] = {
                'total_runs': 0, 'successful_runs': 0, 'total_matches': 0, 'total_matching_time': 0.0
            }
        
        detector_analysis[detector]['total_runs'] += 1
        detector_analysis[detector]['total_matches'] += result['good_matches']
        detector_analysis[detector]['total_inliers'] += result['inlier_matches']
        detector_analysis[detector]['total_detection_time'] += result['detection_time']
        detector_analysis[detector]['avg_match_quality'] += result['match_quality']
        
        matcher_analysis[matcher]['total_runs'] += 1
        matcher_analysis[matcher]['total_matches'] += result['good_matches']
        matcher_analysis[matcher]['total_matching_time'] += result['matching_time']
        
        if result['status'] == 'success':
            detector_analysis[detector]['successful_runs'] += 1
            matcher_analysis[matcher]['successful_runs'] += 1
    
    # Calculate averages
    for detector in detector_analysis:
        stats = detector_analysis[detector]
        if stats['total_runs'] > 0:
            stats['avg_matches'] = stats['total_matches'] / stats['total_runs']
            stats['avg_inliers'] = stats['total_inliers'] / stats['total_runs']
            stats['avg_detection_time'] = stats['total_detection_time'] / stats['total_runs']
            stats['avg_match_quality'] = stats['avg_match_quality'] / stats['total_runs']
            stats['success_rate'] = stats['successful_runs'] / stats['total_runs'] * 100
    
    for matcher in matcher_analysis:
        stats = matcher_analysis[matcher]
        if stats['total_runs'] > 0:
            stats['avg_matches'] = stats['total_matches'] / stats['total_runs']
            stats['avg_matching_time'] = stats['total_matching_time'] / stats['total_runs']
            stats['success_rate'] = stats['successful_runs'] / stats['total_runs'] * 100
    
    # Save JSON summary
    summary_data = {
        'detector_analysis': detector_analysis,
        'matcher_analysis': matcher_analysis,
        'total_experiments': len(valid_results)
    }
    
    with open(f"{analysis_dir}/analysis_summary.json", 'w', encoding='utf-8') as f:
        json.dump(summary_data, f, indent=2, ensure_ascii=False, default=float)
  ```,
  caption: [analyse_results()],
  kind: "code",
  supplement: [コード]
)

#figure(
  ```python
  def main():
    """Main experiment function"""
    image_dir = "match_pics/"
    output_base_dir = "feature_matching_results"
    
    if not os.path.exists(output_base_dir):
        os.makedirs(output_base_dir)
    
    # Find image pairs
    image_pairs = find_image_pairs(image_dir)
    
    # Configuration
    detector_types = ["SIFT", "ORB", "AKAZE", "KAZE", "BRISK"]
    matcher_types = ["BF", "FLANN"]
    
    # Create all combinations
    all_combinations = []
    for base_name, paths in sorted(image_pairs.items()):
        for detector_type in detector_types:
            for matcher_type in matcher_types:
                all_combinations.append({
                    "base_name": base_name,
                    "image1_path": paths['a'],
                    "image2_path": paths['b'],
                    "detector_type": detector_type,
                    "matcher_type": matcher_type
                })
    
    # Run experiments
    all_results = []
    for combo in tqdm(all_combinations, desc="Running experiments"):
        current_output_dir = os.path.join(output_base_dir, combo["base_name"])
        os.makedirs(current_output_dir, exist_ok=True)
        
        result = perform_feature_matching(
            combo["image1_path"], combo["image2_path"],
            combo["detector_type"], combo["matcher_type"],
            output_dir=current_output_dir
        )
        
        all_results.append(result)
    
    # Analyze results
    analyze_results(all_results, output_base_dir)
  ```,
  caption: [main()],
  kind: "code",
  supplement: [コード]
)