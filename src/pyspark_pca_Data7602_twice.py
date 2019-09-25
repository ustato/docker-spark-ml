# -*- coding: utf-8 -*-
from pyspark.sql import SparkSession
from pyspark.ml.feature import PCA, VectorAssembler, StandardScaler

# Initialize SparkSession
spark = (SparkSession
         .builder
         .appName("news")
         .enableHiveSupport()
         .getOrCreate())

# Read raw data
df = spark.read.csv('/home/worker/data/Data7602.csv', header=True, inferSchema=True, mode="DROPMALFORMED", encoding='UTF-8').drop("Area")
df = df.union(df)

print("==== 生データ ====")
df.show(truncate=False)

assembler = VectorAssembler(inputCols=df.columns[1:], outputCol="変量")
feature_vectors = assembler.transform(df)
feature_vectors.show()


scaler = StandardScaler(inputCol="変量", outputCol="標準化変量", withStd=True, withMean=True)
scalerModel = scaler.fit(feature_vectors)
std_feature_vectors = scalerModel.transform(feature_vectors)

print("==== 標準化されたデータ ====")
std_feature_vectors.select("標準化変量").show(truncate=False)

# build PCA model
pca = PCA(k=2, inputCol="標準化変量", outputCol="主成分得点")
pcaModel = pca.fit(std_feature_vectors)

print("==== 固有ベクトル ====")
print(pcaModel.pc)

print("==== 寄与率 ====")
print(pcaModel.explainedVariance)

pca_score = pcaModel.transform(std_feature_vectors).select("主成分得点")
print("==== 主成分得点 ====")

pca_score.show(truncate=False)

print("==== 元のデータフレーム行数 ====")
print((df.count(), len(df.columns)))
