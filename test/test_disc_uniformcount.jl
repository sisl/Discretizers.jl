@test array_matches(binedges(DiscretizeUniformCount(2), [1.0,2.0,3.0,4.0,5.0,6.0]), [1.0, 3.5, 6.0], 1e-8)
@test array_matches(binedges(DiscretizeUniformCount(2), [6.0,2.0,30.0,4.0,1.0,1.0]), [1.0, 3.0, 30.0], 1e-8)
@test array_matches(binedges(DiscretizeUniformCount(2), [1.0,2.0,3.0,4.0,5.0]), [1.0, 3.5, 5.0], 1e-8)
@test array_matches(binedges(DiscretizeUniformCount(3), [1.0,2.0,3.0,4.0,5.0]), [1.0, 2.5, 4.5, 5.0], 1e-8)
@test_throws ErrorException binedges(DiscretizeUniformCount(3), [1.0, 1.0])

@test binedges(DiscretizeUniformCount(2), [1,2]) == [1, 2, 2]
@test binedges(DiscretizeUniformCount(3), [1,2,2,2,3]) == [1, 2, 3, 3]
@test binedges(DiscretizeUniformCount(3), [1,2,2,2,50]) == [1, 2, 26, 50]
@test binedges(DiscretizeUniformCount(3), [1,2,2,2,51]) == [1, 2, 27, 51]
@test binedges(DiscretizeUniformCount(3), [1,1,1,2,3,4,50,51,52]) == [1, 2, 27, 52]