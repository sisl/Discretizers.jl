
@test array_matches(binedges(DiscretizeUniformWidth(2), [1.0,2.0,3.0,4.0,5.0,6.0]), [1.0, 3.5, 6.0], 1e-8)
@test array_matches(binedges(DiscretizeUniformWidth(2), [6.0,2.0,30.0,4.0,1.0,1.0]), [1, 15.5, 30], 1e-8)
@test array_matches(binedges(DiscretizeUniformWidth(3), [1.0,2.0,3.0,4.0,5.0,6.0,7.0]), [1.0, 3.0, 5.0, 7.0], 1e-8)
@test_throws AssertionError binedges(DiscretizeUniformWidth(3), [1.0, 1.0])

@test array_matches(binedges(DiscretizeUniformWidth(2), [1,2,3,4,6]), [1.0, 3.5, 6.0], 1e-8)
@test array_matches(binedges(DiscretizeUniformWidth(3), [1,3,7]), [1.0,3.0,5.0,7.0], 1e-8)
@test_throws AssertionError binedges(DiscretizeUniformWidth(3), [1, 1])