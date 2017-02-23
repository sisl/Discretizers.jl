@test array_matches(binedges(DiscretizeBayesianBlocks(), [1.0,2.0,3.0,4.0,5.0,6.0]), [1.0, 6.0], 1e-8)
@test array_matches(binedges(DiscretizeBayesianBlocks(), [6.0,2.0,30.0,4.0,1.0,1.0]), [1.0, 1.5, 30.0], 1e-8)

@test binedges(DiscretizeBayesianBlocks(), [1,2,3,4,5,6]) == [1.0, 6.0]
@test binedges(DiscretizeBayesianBlocks(), [1,2,2,2,3]) == [1.0, 3.0]
