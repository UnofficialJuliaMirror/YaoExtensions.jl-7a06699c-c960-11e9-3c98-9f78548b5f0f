using Test
using YaoExtensions.AD, YaoExtensions
using Yao
using Random

using SparseArrays, LuxurySparse, LinearAlgebra

@testset "mat rot/shift/phase" begin
    Random.seed!(5)
    for G in [X, Y, Z, ConstGate.SWAP, ConstGate.CZ, ConstGate.CNOT]
        @test test_mat_back(ComplexF64, rot(G, 0.0), 0.5; δ=1e-5)
    end

    for G in [ShiftGate, PhaseGate]
        @test test_mat_back(ComplexF64, G(0.0), 0.5; δ=1e-5)
    end

    G = time_evolve(put(3, 2=>X), 0.0)
    @test test_mat_back(ComplexF64, G, 0.5; δ=1e-5)
end

@testset "mat put block, control block" begin
    Random.seed!(5)
    for use_outeradj in [false, true]
        # put block, diagonal
        @test test_mat_back(ComplexF64, put(3, 1=>Rz(0.5)), 0.5; δ=1e-5, use_outeradj=use_outeradj)
        @test test_mat_back(ComplexF64, control(3, (2,3), 1=>Rz(0.5)), 0.5; δ=1e-5, use_outeradj=use_outeradj)
        # dense matrix
        @test test_mat_back(ComplexF64, put(3, 1=>Rx(0.5)), 0.5; δ=1e-5, use_outeradj=use_outeradj)
        @test test_mat_back(ComplexF64, control(3, (2,3), 1=>Rx(0.5)), 0.5; δ=1e-5, use_outeradj=use_outeradj)
        # sparse matrix csc
        @test test_mat_back(ComplexF64, put(3, (1,2)=>rot(SWAP, 0.5)), 0.5; δ=1e-5, use_outeradj=use_outeradj)
        @test test_mat_back(ComplexF64, control(3, (3,), (1,2)=>rot(SWAP, 0.5)), 0.5; δ=1e-5, use_outeradj=use_outeradj)
    end

    # is permatrix even possible?
    #@test test_mat_back(ComplexF64, put(3, 1=>matblock(pmrand(2))), [0.5, 0.6]; δ=1e-5)
    # ignore identity matrix.
end

@testset "mat concentrate" begin
    Random.seed!(5)
    @test test_mat_back(ComplexF64, concentrate(3, control(2, 2,1=>shift(0.0)), (3,1)), 0.5; δ=1e-5)
end

@testset "mat chain" begin
    Random.seed!(5)
    @test test_mat_back(ComplexF64, chain(3, control(3, 2,1=>shift(0.0))), 0.5; δ=1e-5)
    @test test_mat_back(ComplexF64, chain(3, put(3, 2=>X), control(3, 2,1=>shift(0.0))), 0.5; δ=1e-5)
    @test test_mat_back(ComplexF64, chain(3, control(3, 2,1=>shift(0.0)), put(3, 2=>X)), 0.5; δ=1e-5)
    @test test_mat_back(ComplexF64, chain(3, control(3, 2,1=>shift(0.0)), NoParams(put(3, 1=>Rx(0.0)))), 0.5; δ=1e-5)
    @test test_mat_back(ComplexF64, chain(3, control(3, 2,1=>shift(0.0)), chain(put(3, 1=>Rx(0.0)), put(3, 2=>Ry(0.0)))), [0.5,0.5,0.5]; δ=1e-5)
    @test test_mat_back(ComplexF64, chain(3, chain(3, put(3, 1=>Rx(0.0)), put(3, 2=>Ry(0.0)))), [0.5,0.5]; δ=1e-5)
end

@testset "mat kron" begin
    use_outeradj=false
    @test test_mat_back(ComplexF64, kron(Rx(0.5), Rz(0.6)), [0.5, 0.5]; δ=1e-5, use_outeradj=use_outeradj)
end

@testset "system test" begin
    for c in [variational_circuit(4), QFTCircuit(4)]
        params = rand(nparameters(c)) * 2π
        @test test_mat_back(ComplexF64, c, params; δ=1e-5, use_outeradj=false)
        for reg0 in [rand_state(4), rand_state(4, nbatch=10)]
            @test test_apply_back(reg0, c, params; δ=1e-5)
        end
    end
end