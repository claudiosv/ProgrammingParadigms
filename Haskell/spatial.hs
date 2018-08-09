module DatapointAggregation ()
where

import Data.List
-- Definition of types and list
type Point = (Double,Double)
type Rectangle = (Point,Point)

myDatapoints = [(2.3,5.4),(3.4,4.8),(6.3,9.4),(7.1,5.4),(1.1,8.5),(8.7,3.3),(9.3,2.3),(4.6,5.8),(7.6,4.9),(2.4,2.8),(3.9,1.1),(8.2,2.3),(4.4,7.2),(5.5,2.3),(9.1,9.8),(9.6,7.1)]

-- End of definitions

inrect :: Point -> Rectangle -> Bool
inrect points rect =
    if (fst points) > fst(fst rect) && (fst points) < fst(snd rect) && (snd points) > snd(fst rect) && (snd points) < snd(snd rect) then True
    else False

boundingbox :: [Point] -> Rectangle -> [Point]
boundingbox points rect =
    filter (\x -> inrect x rect) points

listx :: [Point] -> [Double]
listx points =
    map (\x -> fst(x)) points --I'm sure a smart Haskell programmer will
    --pass a lambda function to replace fst to avoid repeating. i don't have time
    -- to figure it out! Sorry for my ugly code.

listy :: [Point] -> [Double]
listy points =
    map (\y -> snd(y)) points

minx :: [Point] -> Double
minx points =
    minimum (listx points)

miny :: [Point] -> Double
miny points =
    minimum (listy points)

maxy :: [Point] -> Double
maxy points =
    maximum (listy points)

maxx :: [Point] -> Double
maxx points =
    maximum (listx points)

minrect :: [Point] -> Rectangle
minrect points =
    ((minx points, miny points), (maxx points, maxy points))

manhat :: (Double, Double) -> (Double, Double) -> Double
manhat (x1, y1) (x2, y2)  =
    abs(x1 - x2) + abs(y1 - y2)

manhatt :: (Double, Double) -> (Double, Double) -> (Double, (Double, Double))
manhatt (x1, y1) (x2, y2)  =
    (abs(x1 - x2) + abs(y1 - y2), (x2, y2))

distances :: (Double, Double) -> [(Double, Double)] -> [Double]
distances (x, y) tuples =
    map (\i -> manhat (x, y) i) tuples

distancest :: (Double, Double) -> [(Double, Double)] -> [(Double, (Double, Double))]
distancest (x, y) tuples =
    map (\i -> manhatt (x, y) i) tuples

mindist :: (Double, Double) -> [(Double, Double)] -> Double
mindist (x, y) tuples =
    minimum(distances (x, y) tuples)

nearestneighbors :: (Double, Double) -> Int -> [(Double, Double)] -> [(Double, Double)]
nearestneighbors (x, y) k tuples =
    take k (map (\i -> snd i) (orderIt (distancest (x, y) tuples)))

-- THIS FUNCTION IS TAKEN FROM EXERCISE SOLUTIONS
-- I have only modified it to sort lists of nested tuples!
orderIt :: Ord a => [(a, (Double, Double))] -> [(a, (Double, Double))]
orderIt [] = []
orderIt x = [minimum x] ++ orderIt (delete (minimum x) x)