for cd in (
    CategoricalDiscretizer([:A=>1, :B=>2, :C=>3]),
    CategoricalDiscretizer([:A, :B, :C], Int),
    CategoricalDiscretizer([:A, :B, :C])
    )

    @test encode(cd, :B) == 2
    @test encode(cd, "B") == 2
    @test encode(cd, [:C, :B, :A, :B, :C]) == [3,2,1,2,3]
    @test encode(cd, [:A :B; :C :A]) == [1 2; 3 1]
    # @test encode(cd, DataArray([:C, :B])) == [3,2]
    @test_throws KeyError encode(cd, :D)
    @test_throws KeyError encode(cd, [:A, :D])

    @test decode(cd, 2) == :B
    @test decode(cd, uint8(2)) == :B
    @test decode(cd, [3,2,1,2,3]) == [:C, :B, :A, :B, :C]
    @test decode(cd, [1 2; 3 1]) == [:A :B; :C :A]
    # @test decode(cd, [3,2]) == DataArray([:C, :B])

    @test nlabels(cd) == 3
    @test supports_encoding(cd, Symbol)
    @test supports_encoding(cd, :A)
    @test supports_decoding(cd, Int)
    @test supports_decoding(cd, 1)
end