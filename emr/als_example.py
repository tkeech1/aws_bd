from __future__ import print_function

import sys
if sys.version >= '3':
    long = int

from pyspark.sql import SparkSession

# $example on$
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml.recommendation import ALS
from pyspark.sql import Row
# $example off$

if __name__ == "__main__":
    spark = SparkSession\
        .builder\
        .appName("ALSExample")\
        .getOrCreate()

    spark.sparkContext.setLogLevel("ERROR")

    # $example on$
    #lines = spark.read.text("data/mllib/als/sample_movielens_ratings.txt").rdd
    #parts = lines.map(lambda row: row.value.split("::"))
    #ratingsRDD = parts.map(lambda p: Row(userId=int(p[0]), movieId=int(p[1]),
    #                                     rating=float(p[2]), timestamp=long(p[3])))

    # tk - custom code to read from S3
    lines = spark.read.text("s3://tdk-bd.io/2019/11/10/23/*").rdd
    parts = lines.map(lambda row: row.value.split(','))
    #Filter out postage, shipping, bank charges, discounts, commissions
    productsOnly = parts.filter(lambda p: p[1][0:5].isdigit())
    #Filter out empty customer ID's
    cleanData = productsOnly.filter(lambda p: p[6].isdigit())
    ratingsRDD = cleanData.map(lambda p: Row(customerId=int(p[6]), itemId=int(p[1][0:5]), rating=1.0))
    # tk - end custom code to read from S3

    ratings = spark.createDataFrame(ratingsRDD)
    (training, test) = ratings.randomSplit([0.8, 0.2])

    # Build the recommendation model using ALS on the training data
    # Note we set cold start strategy to 'drop' to ensure we don't get NaN evaluation metrics
    #als = ALS(maxIter=5, regParam=0.01, userCol="userId", itemCol="movieId", ratingCol="rating",
    #          coldStartStrategy="drop")
    als = ALS(maxIter=5, regParam=0.01, userCol="customerId", itemCol="itemId", ratingCol="rating", coldStartStrategy="drop")
    model = als.fit(training)

    # Evaluate the model by computing the RMSE on the test data
    predictions = model.transform(test)
    evaluator = RegressionEvaluator(metricName="rmse", labelCol="rating",
                                    predictionCol="prediction")
    rmse = evaluator.evaluate(predictions)
    print("Root-mean-square error = " + str(rmse))

    # Generate top 10 movie recommendations for each user
    userRecs = model.recommendForAllUsers(10)
    # Generate top 10 user recommendations for each movie
    movieRecs = model.recommendForAllItems(10)

    # Generate top 10 movie recommendations for a specified set of users
    users = ratings.select(als.getUserCol()).distinct().limit(3)
    userSubsetRecs = model.recommendForUserSubset(users, 10)
    # Generate top 10 user recommendations for a specified set of movies
    movies = ratings.select(als.getItemCol()).distinct().limit(3)
    movieSubSetRecs = model.recommendForItemSubset(movies, 10)
    # $example off$
    userRecs.show()
    movieRecs.show()
    userSubsetRecs.show()
    movieSubSetRecs.show()

    spark.stop()