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

#ifndef CFD3D_PARTICLETRACER_HPP
#define CFD3D_PARTICLETRACER_HPP

#include <string>
#include <vector>
#include <glm/glm.hpp>
#include "Defines.hpp"
#include "TrajectoryAttributes.hpp"

/**
 * SteadyFlowParticleTracer is the super-class of StreamlineTracer.
 * TimeVaryingParticleTracer is the super-class of PathlineTracer, StreaklineTracer.
 * They are used for tracing the paths of particles through the fluid in order to create the characteristic lines
 * of our flow (sometimes also called field lines).
 *
 * Characteristic lines are tangential to the flow.
 * => Line tangent = vector field direction
 *
 * dx(t) / dt = v(x(t), t)
 * x(0) = x_0
 *
 * Characterization of flow: Unsteady/time-varying vs steady flow.
 *
 * Types of characteristic lines of a flow:
 * - Path lines: Follow massless particles through time and space.
 * - Streak lines. Continuously release particles into flow at fixed position and connect particles.
 * - Stream lines: Trajectory of massless particles at one time step.
 * If the flow is steady, all types of characteristic lines are equal.
 *
 * Other possibilities for visualization in a future implementation: e.g. streak surfaces.
 * They are created by seeding particles along a curve and connecting them to form surfaces.
 */


/**
 * A super class for particle tracers for steady flows. This class is implemented by @see StreamlineTracer.
 * A steady flow is not dependent on time, thus can be executed on a single snapshot of U, V, and W forming the velocity
 * vector field.
 */
class SteadyFlowParticleTracer
{
public:
    /**
     * Traces the characteristic lines of a given steady velocity vector field.
     * @param particleSeedingLocations The seeding locations of the particles to trace in world space.
     * @param gridOrigin The origin of the grid in world coordinates.
     * @param gridSize The size of the grid (i.e. the extent in x, y and z) of the grid.
     * @param dt The time step to use for integrating the particle position.
     * @param imax Number of cells in x direction inside of the domain.
     * @param jmax Number of cells in y direction inside of the domain.
     * @param kmax Number of cells in z direction inside of the domain.
     * @param dx The cell size in x direction.
     * @param dy The cell size in y direction.
     * @param dz The cell size in z direction.
     * @param U The velocities in x direction.
     * @param V The velocities in y direction.
     * @param W The velocities in z direction.
     * @param P The pressure values.
     * @param T The temperature values.
     * @return The characteristic lines (an array containing the arrays of line points).
     */
    virtual Trajectories trace(
            const std::vector<rvec3> &particleSeedingLocations, const rvec3 &gridOrigin, const rvec3 &gridSize, Real dt,
            int imax, int jmax, int kmax, Real dx, Real dy, Real dz, Real *U, Real *V, Real *W, Real *P, Real *T)=0;
};

/**
 * A super class for particle tracers for time varying flows. This class is implemented by @see PathlineTracer and @see
 * StreaklineTracer.
 * NOTE: PathlineTracer and StreaklineTracer were unfinished and thus removed from the final project.
 */
class TimeVaryingParticleTracer
{
public:
    /**
     * Sets the seeding positions of the particles to trace during the (time-dependent) simulation.
     * @param particleSeedingLocations The seeding locations of the particles to trace in world space.
     * @param gridOrigin The origin of the grid in world coordinates.
     * @param gridSize The size of the grid (i.e. the extent in x, y and z) of the grid.
     */
    virtual void setParticleSeedingLocations(
            const rvec3 &gridOrigin, const rvec3 &gridSize, const std::vector<rvec3> &particleSeedingLocations)=0;

    /**
     * Integrates the position of all particles with the passed time step size.
     * @param t The current time in the simulation.
     * @param dt The time step to use for integrating the particle position.
     * @param imax Number of cells in x direction inside of the domain.
     * @param jmax Number of cells in y direction inside of the domain.
     * @param kmax Number of cells in z direction inside of the domain.
     * @param dx The cell size in x direction.
     * @param dy The cell size in y direction.
     * @param dz The cell size in z direction.
     * @param U The velocities in x direction.
     * @param V The velocities in y direction.
     * @param W The velocities in z direction.
     * @param P The pressure values.
     * @param T The temperature values.
     */
    virtual void timeStep(
            Real t, Real dt, int imax, int jmax, int kmax, Real dx, Real dy, Real dz,
            Real *U, Real *V, Real *W, Real *P, Real *T)=0;

    /**
     * Get the characteristic lines generated by the calls @see timeStep.
     * @param imax Number of cells in x direction inside of the domain.
     * @param jmax Number of cells in y direction inside of the domain.
     * @param kmax Number of cells in z direction inside of the domain.
     * @param dx The cell size in x direction.
     * @param dy The cell size in y direction.
     * @param dz The cell size in z direction.
     * @param U The velocities in x direction.
     * @param V The velocities in y direction.
     * @param W The velocities in z direction.
     * @param P The pressure values.
     * @param T The temperature values.
     * @return The characteristic lines (an array containing the arrays of line points).
     */
    virtual Trajectories getTrajectories(
            int imax, int jmax, int kmax, Real dx, Real dy, Real dz,
            Real *U, Real *V, Real *W, Real *P, Real *T)=0;
};

/**
 * Integrates a particle position in the given velocity field using the passed time step size with the explicit Euler
 * scheme.
 * @param particleStartPosition The position of the particle in world coordinates.
 * @param gridOrigin The origin of the grid in world coordinates.
 * @param gridSize The size of the grid (i.e. the extent in x, y and z) of the grid.
 * @param imax Number of cells in x direction inside of the domain.
 * @param jmax Number of cells in y direction inside of the domain.
 * @param kmax Number of cells in z direction inside of the domain.
 * @param U The velocities in x direction.
 * @param V The velocities in y direction.
 * @param W The velocities in z direction.
 * @param dt The time step to use for integrating the particle position.
 * @return The integrated particle position at time t+dt.
 */
rvec3 integrateParticlePositionEuler(
        const rvec3 &particlePosition, const rvec3 &gridOrigin, const rvec3 &gridSize,
        int imax, int jmax, int kmax, Real *U, Real *V, Real *W, Real dt);

/**
 * This function returns the particle seeding locations for a special scenario.
 * This is necessary, as sometimes we might want to seed the particles at inflow walls, sometimes at
 * @param scenarioName The name of the scenario to get the particle seeding locations for.
 * @param numParticles The number of particles to seed.
 * @param gridOrigin The origin of the grid in world coordinates.
 * @param gridSize The size of the grid (i.e. the extent in x, y and z) of the grid.
 * @return A list of particle seeding locations.
 */
std::vector<rvec3> getParticleSeedingLocationsForScenario(
        const std::string &scenarioName, int numParticles, const rvec3 &gridOrigin, const rvec3 &gridSize);

#endif //CFD3D_PARTICLETRACER_HPP
