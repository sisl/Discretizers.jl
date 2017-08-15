
disc = datalineardiscretizer([0.0,1.0,2.0])

@test supports_encoding(disc, 0.0)
@test supports_encoding(disc, 0.5)
@test supports_encoding(disc, 1.5)
@test supports_encoding(disc, 2.0)
@test supports_encoding(disc, Inf)
@test !supports_encoding(disc, NaN)
@test supports_encoding(disc, 2.5)
@test supports_encoding(disc, -0.5)

@test encode(disc, 0.0) == 1
@test encode(disc, 0.5) == 1
@test encode(disc, 1.0) == 2
@test encode(disc, 1.5) == 2
@test encode(disc, 2.0) == 2
@test encode(disc, 2.5) == 2
@test encode(disc, Inf) == 3
@test encode(disc, -0.5) == 1
@test array_matches(encode(disc, [0.0,0.5,1.5,Inf]), [1,1,2,3])

@test 0.0 ≤ decode(disc, 1) ≤ 1.0
@test 1.0 ≤ decode(disc, 2) ≤ 2.0
@test isinf(decode(disc, 3))
@test isapprox(decode(disc, 1, SAMPLE_BIN_CENTER), 0.5)
@test isapprox(decode(disc, 2, SAMPLE_BIN_CENTER), 1.5)

@test isapprox(max(disc), 2.0)
@test isapprox(min(disc), 0.0)
@test extrema(disc) == (0.0,2.0)
@test isapprox(totalwidth(disc), 2.0)

@test nlabels(disc) == 3
@test array_matches(bincenters(disc), [0.5,1.5])
@test isapprox(binwidth(disc, 1), 1.0)
@test isapprox(binwidth(disc, 2), 1.0)
@test array_matches(binwidths(disc), [1.0,1.0])

###

disc = datalineardiscretizer([0.0,1.0,2.0], missing_key=NaN, force_outliers_to_closest=false)

@test supports_encoding(disc, 0.0)
@test supports_encoding(disc, 0.5)
@test supports_encoding(disc, 1.5)
@test supports_encoding(disc, 2.0)
@test !supports_encoding(disc, Inf)
@test supports_encoding(disc, NaN)
@test !supports_encoding(disc, 2.5)
@test !supports_encoding(disc, -0.5)

@test encode(disc, 0.0) == 1
@test encode(disc, 0.5) == 1
@test encode(disc, 1.0) == 2
@test encode(disc, 1.5) == 2
@test encode(disc, 2.0) == 2
@test encode(disc, NaN) == 3
@test array_matches(encode(disc, [0.0,0.5,1.5,NaN]), [1,1,2,3])