/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef FDAS_ALIGNEDBUFFER_H
#define FDAS_ALIGNEDBUFFER_H

#include <memory>

template <typename T, size_t alignment>
class AlignedBuffer {
public:
    AlignedBuffer() = default;
    ~AlignedBuffer() = default;

    T* allocate(size_t n_elements) {
        auto extra = alignment / sizeof(T) + 1;
        alloc.reset(new T[n_elements + extra]);

        auto alloc_uint = reinterpret_cast<std::uintptr_t>(alloc.get());
        auto offset = alloc_uint & (alignment - 1);
        if (offset == 0)
            aligned = alloc.get();
        auto aligned_uint = alloc_uint - offset + alignment;
        aligned = reinterpret_cast<T*>(aligned_uint);
        return aligned;
    }

    T* operator()() {
        return aligned;
    }

private:
    std::unique_ptr<T[]> alloc;
    T* aligned;
};

#endif // FDAS_ALIGNEDBUFFER_H
