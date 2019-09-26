# -*- coding: utf-8 -*-
from pyspark.sql import SparkSession
from pyspark.ml.feature import PCA, VectorAssembler, StandardScaler
from mmlspark.lightgbm import LightGBMRegressor

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


print("==== LightGBMの学習 ====")
model = LightGBMRegressor(alpha=0.3,
                          learningRate=0.3,
                          numIterations=100,
                          numLeaves=31,
                          featuresCol='変量',
                          labelCol='geo_count').fit(feature_vectors)


print("==== 元のデータフレーム行数 ====")
print((df.count(), len(df.columns)))
