/*
 * BSD 2-Clause License
 *
 * Copyright (c) 2019, Christoph Neuhauser, Stefan Haas, Paul Ng
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "BoundaryValuesCuda.hpp"

__device__ inline bool isFluid(unsigned int flag) { return (flag >> 0) & 1; }
__device__ inline bool isNoSlip(unsigned int flag) { return (flag >> 1) & 1; }
__device__ inline bool isFreeSlip(unsigned int flag) { return (flag >> 2) & 1; }
__device__ inline bool isOutflow(unsigned int flag) { return (flag >> 3) & 1; }
__device__ inline bool isInflow(unsigned int flag) { return (flag >> 4) & 1; }
__device__ inline bool B_L(unsigned int flag) { return (flag >> 5) & 1; }
__device__ inline bool B_R(unsigned int flag) { return (flag >> 6) & 1; }
__device__ inline bool B_D(unsigned int flag) { return (flag >> 7) & 1; }
__device__ inline bool B_U(unsigned int flag) { return (flag >> 8) & 1; }
__device__ inline bool B_B(unsigned int flag) { return (flag >> 9) & 1; }
__device__ inline bool B_F(unsigned int flag) { return (flag >> 10) & 1; }
__device__ inline bool isHot(unsigned int flag) { return (flag >> 11) & 1; }
__device__ inline bool isCold(unsigned int flag) { return (flag >> 12) & 1; }
__device__ inline bool isCoupling(unsigned int flag) { return (flag >> 13) & 1; }

__global__ void setLeftRightBoundariesCuda(
    Real T_h, Real T_c,
    int imax, int jmax, int kmax,
    Real *U, Real *V, Real *W, Real *T,
    FlagType *Flag) {

    int j = blockIdx.x + threadIdx.y + 1;
    int k = blockIdx.y + threadIdx.x + 1;
    // Set the boundary values for the pressure on the y-z-planes.
    if (j <= imax && k<= jmax){
        // Left wall
        if (isNoSlip(Flag[IDXFLAG(0,j,k)])) {
            U[IDXU(0,j,k)] = 0.0;
            V[IDXV(0,j,k)] = -V[IDXV(1,j,k)];
            W[IDXW(0,j,k)] = -W[IDXW(1,j,k)];
        }
        else if (isFreeSlip(Flag[IDXFLAG(0,j,k)])) {
            U[IDXU(0,j,k)] = 0.0;
            V[IDXV(0,j,k)] = V[IDXV(1,j,k)];
            W[IDXW(0,j,k)] = W[IDXW(1,j,k)];
        }
        else if (isOutflow(Flag[IDXFLAG(0,j,k)])) {
            U[IDXU(0,j,k)] = U[IDXU(1,j,k)];
            V[IDXV(0,j,k)] = V[IDXV(1,j,k)];
            W[IDXW(0,j,k)] = W[IDXW(1,j,k)];
        }
        // Right wall
        if (isNoSlip(Flag[IDXFLAG(imax+1,j,k)])) {
            U[IDXU(imax,j,k)] = 0.0;
            V[IDXV(imax+1,j,k)] = -V[IDXV(imax,j,k)];
            W[IDXW(imax,j,k)] = -W[IDXW(imax,j,k)];
        }
        else if (isFreeSlip(Flag[IDXFLAG(imax+1,j,k)])) {
            U[IDXU(imax,j,k)] = 0.0;
            V[IDXV(imax+1,j,k)] = V[IDXV(imax,j,k)];
            W[IDXW(imax,j,k)] = W[IDXW(imax,j,k)];
        }
        else if (isOutflow(Flag[IDXFLAG(imax+1,j,k)])) {
            U[IDXU(imax,j,k)] = U[IDXU(imax-1,j,k)];
            V[IDXV(imax+1,j,k)] = V[IDXV(imax,j,k)];
            W[IDXW(imax,j,k)] = W[IDXW(imax-1,j,k)];                
        }

        // Left boundary T
        if (isHot(Flag[IDXFLAG(0,j,k)])) {
            T[IDXT(0,j,k)] = 2 * T_h - T[IDXT(1,j,k)];
        } else if (isCold(Flag[IDXFLAG(0,j,k)])) {
            T[IDXT(0,j,k)] = 2 * T_c - T[IDXT(1,j,k)];
        } else {
            T[IDXT(0,j,k)] = T[IDXT(1,j,k)];
        }
        
        // Right boundary T
        if (isHot(Flag[IDXFLAG(imax+1,j,k)])) {
            T[IDXT(imax+1,j,k)] = 2 * T_h - T[IDXT(imax,j,k)];
        }  else if (isCold(Flag[IDXFLAG(imax+1,j,k)])) {
            T[IDXT(imax+1,j,k)] = 2 * T_c - T[IDXT(imax,j,k)];
        } else {
            T[IDXT(imax+1,j,k)] = T[IDXT(imax,j,k)];
        }            
    }
}

__global__ void setDownUpBoundariesCuda(
    Real T_h, Real T_c,
    int imax, int jmax, int kmax,
    Real *U, Real *V, Real *W, Real *T,
    FlagType *Flag) {
    int i = blockIdx.x + threadIdx.y + 1;
    int k = blockIdx.y + threadIdx.x + 1;
    // Set the boundary values for the pressure on the x-z-planes.
    if (i <= imax && k<= jmax){
        // Down wall
        if (isNoSlip(Flag[IDXFLAG(i,0,k)])) {
            U[IDXU(i,0,k)] = -U[IDXU(i,1,k)];
            V[IDXV(i,0,k)] = 0.0;
            W[IDXW(i,0,k)] = -W[IDXW(i,1,k)];
        } else if (isFreeSlip(Flag[IDXFLAG(i,0,k)])) {
            U[IDXU(i,0,k)] = U[IDXU(i,1,k)];
            V[IDXV(i,0,k)] = 0.0;
            W[IDXW(i,0,k)] = W[IDXW(i,1,k)];
        } else if (isOutflow(Flag[IDXFLAG(i,0,k)])) {
            U[IDXU(i,0,k)] = U[IDXU(i,1,k)];
            V[IDXV(i,0,k)] = V[IDXV(i,1,k)];
            W[IDXW(i,0,k)] = W[IDXW(i,1,k)];
        }
        // Up wall
        if (isNoSlip(Flag[IDXFLAG(i,jmax+1,k)])) {
            U[IDXU(i,jmax+1,k)] = -U[IDXU(i,jmax,k)];
            V[IDXV(i,jmax,k)] = 0.0;
            W[IDXW(i,jmax,k)] = -W[IDXW(i,jmax,k)];
        } else if (isFreeSlip(Flag[IDXFLAG(i,jmax+1,k)])) {
            U[IDXU(i,jmax+1,k)] = U[IDXU(i,jmax,k)];
            V[IDXV(i,jmax,k)] = 0.0;
            W[IDXW(i,jmax,k)] = W[IDXW(i,jmax,k)];
        } else if (isOutflow(Flag[IDXFLAG(i,jmax+1,k)])) {
            U[IDXU(i,jmax+1,k)] = U[IDXU(i,jmax,k)];
            V[IDXV(i,jmax,k)] = V[IDXV(i,jmax-1,k)];
            W[IDXW(i,jmax,k)] = W[IDXW(i,jmax-1,k)];                
        }

        // Down boundary T
        if (isHot(Flag[IDXFLAG(i,0,k)])) {
            T[IDXT(i,0,k)] = 2 * T_h - T[IDXT(i,1,k)];
        } else if (isCold(Flag[IDXFLAG(i,0,k)])) {
            T[IDXT(i,0,k)] = 2 * T_c - T[IDXT(i,1,k)];
        } else {
            T[IDXT(i,0,k)] = T[IDXT(i,1,k)];
        }
        
        // Up boundary T
        if (isHot(Flag[IDXFLAG(i,jmax+1,k)])) {
            T[IDXT(i,jmax+1,k)] = 2 * T_h - T[IDXT(i,jmax,k)];
        } else if (isCold(Flag[IDXFLAG(i,jmax+1,k)])) {
            T[IDXT(i,jmax+1,k)] = 2 * T_c - T[IDXT(i,jmax,k)];
        } else {
            T[IDXT(i,jmax+1,k)] = T[IDXT(i,jmax,k)];
        }            
    }
}

__global__ void setFrontBackBoundariesCuda(
    Real T_h, Real T_c,
    int imax, int jmax, int kmax,
    Real *U, Real *V, Real *W, Real *T,
    FlagType *Flag) {
    int i = blockIdx.x + threadIdx.y + 1;
    int j = blockIdx.y + threadIdx.x + 1;
    
    // Set the boundary values for the pressure on the x-y-planes.
    if (i <= imax && j <= jmax){
        // Front wall
        if (isNoSlip(Flag[IDXFLAG(i,j,0)])) {
            U[IDXU(i,j,0)] = -U[IDXU(i,j,1)];
            V[IDXV(i,j,0)] = -V[IDXV(i,j,1)];
            W[IDXW(i,j,0)] = 0.0;
        }
        else if (isFreeSlip(Flag[IDXFLAG(i,j,0)])) {
            U[IDXU(i,j,0)] = U[IDXU(i,j,1)];
            V[IDXV(i,j,0)] = V[IDXV(i,j,1)];
            W[IDXW(i,j,0)] = 0.0;
        }
        else if (isOutflow(Flag[IDXFLAG(i,j,0)])) {
            U[IDXU(i,j,0)] = U[IDXU(i,j,1)];
            V[IDXV(i,j,0)] = V[IDXV(i,j,1)];
            W[IDXW(i,j,0)] = W[IDXW(i,j,1)];
        }
        // Back wall
        if (isNoSlip(Flag[IDXFLAG(i,j,kmax+1)])) {
            U[IDXU(i,j,kmax)] = -U[IDXU(i,j,kmax)];
            V[IDXV(i,j,kmax)] = -V[IDXV(i,j,kmax)];
            W[IDXW(i,j,kmax+1)] = 0.0;
        }
        else if (isFreeSlip(Flag[IDXFLAG(i,j,kmax+1)])) {
            U[IDXU(i,j,kmax)] = U[IDXU(i,j,kmax)];
            V[IDXV(i,j,kmax)] = V[IDXV(i,j,kmax)];
            W[IDXW(i,j,kmax+1)] = 0.0;
        }
        else if (isOutflow(Flag[IDXFLAG(i,j,kmax+1)])) {
            U[IDXU(i,j,kmax)] = U[IDXU(i,j,kmax)];
            V[IDXV(i,j,kmax)] = V[IDXV(i,j,kmax)];
            W[IDXW(i,j,kmax+1)] = W[IDXW(i,j,kmax)];             
        }

        // Front boundary T
        if (isHot(Flag[IDXFLAG(i,j,0)])) {
            T[IDXT(i,j,0)] = 2 * T_h - T[IDXT(i,j,1)];
        } 
        else if (isCold(Flag[IDXFLAG(i,j,0)])) {
            T[IDXT(i,j,0)] = 2 * T_c - T[IDXT(i,j,1)];
        }
        else {
            T[IDXT(i,j,0)] = T[IDXT(i,j,1)];
        }
        
        // Back boundary T
        if (isHot(Flag[IDXFLAG(i,j,kmax+1)])) {
            T[IDXT(i,j,kmax+1)] = 2 * T_h - T[IDXT(i,j,kmax)];
        } 
        else if (isCold(Flag[IDXFLAG(i,j,kmax+1)])) {
            T[IDXT(i,j,kmax+1)] = 2 * T_c - T[IDXT(i,j,kmax)];
        }
        else {
            T[IDXT(i,j,kmax+1)] = T[IDXT(i,j,kmax)];
        }            
    }
}

void setBoundaryValuesCuda(
        Real T_h, Real T_c,
        int imax, int jmax, int kmax,
        Real *U, Real *V, Real *W, Real *T,
        FlagType *Flag) {
    dim3 dimBlock(32,32);
    dim3 dimGrid_x_y(iceil(imax,dimBlock.y),iceil(jmax,dimBlock.x));
    setFrontBackBoundariesCuda<<<dimGrid_x_y,dimBlock>>>(T_h, T_c, imax, jmax, kmax, U, V, W, T, Flag);

    dim3 dimGrid_x_z(iceil(imax,dimBlock.y),iceil(kmax,dimBlock.x));
    setDownUpBoundariesCuda<<<dimGrid_x_z,dimBlock>>>(T_h, T_c, imax, jmax, kmax, U, V, W, T, Flag);

    dim3 dimGrid_y_z(iceil(jmax,dimBlock.y),iceil(kmax,dimBlock.x));
    setLeftRightBoundariesCuda<<<dimGrid_y_z,dimBlock>>>(T_h, T_c, imax, jmax, kmax, U, V, W, T, Flag);
}

void setBoundaryValuesScenarioSpecificCuda(
        const std::string &scenarioName,
        int imax, int jmax, int kmax,
        Real *U, Real *V, Real *W,
        FlagType *Flag) {
    // TODO: Implement.
}
