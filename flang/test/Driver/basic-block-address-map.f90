! Test that flang handles -fbasic-block-address-map and -fbasic-block-sections=
! as clang does, and emits the basic block address map section.

! REQUIRES: riscv-registered-target

! The driver forwards -fbasic-block-address-map where clang allows it.
! RUN: %flang --target=x86_64-unknown-linux-gnu -fbasic-block-address-map -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=FWD
! RUN: %flang --target=aarch64-unknown-linux-gnu -fbasic-block-address-map -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=FWD
! FWD: "-fc1"{{.*}}"-fbasic-block-address-map"

! RUN: %flang --target=x86_64-unknown-linux-gnu -fbasic-block-address-map -fno-basic-block-address-map -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=NONE
! RUN: %flang --target=riscv64-unknown-linux-gnu -fbasic-block-sections=none -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=NONE
! NONE-NOT: error
! NONE-NOT: warning
! NONE: "-fc1"
! NONE-NOT: "-fbasic-block-address-map"

! RUN: not %flang --target=riscv64-unknown-linux-gnu -fbasic-block-address-map -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=UNSUP-TARGET
! UNSUP-TARGET: error: unsupported option '-fbasic-block-address-map' for target 'riscv64-unknown-linux-gnu'

! -fbasic-block-sections=labels becomes -fbasic-block-address-map on every
! target, with clang's deprecation warning.
! RUN: %flang --target=riscv64-unknown-linux-gnu -fbasic-block-sections=labels -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=LABELS
! RUN: %flang --target=x86_64-unknown-linux-gnu -fbasic-block-sections=labels -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=LABELS
! LABELS: warning: argument '-fbasic-block-sections=labels' is deprecated, use '-fbasic-block-address-map' instead
! LABELS: "-fc1"{{.*}}"-fbasic-block-address-map"

! flang has no basic block sections: the other values are rejected.
! RUN: not %flang --target=x86_64-unknown-linux-gnu -fbasic-block-sections=all -fsyntax-only -### %s 2>&1 | FileCheck %s --check-prefix=UNSUP-VALUE
! UNSUP-VALUE: error: unsupported argument 'all' to option '-fbasic-block-sections='

! The frontend emits the section only when asked to.
! RUN: %flang_fc1 -triple riscv64-unknown-linux-gnu -fbasic-block-address-map -S %s -o - | FileCheck %s --check-prefix=ASM
! ASM: .section .llvm_bb_addr_map
! RUN: %flang_fc1 -triple riscv64-unknown-linux-gnu -S %s -o - | FileCheck %s --check-prefix=NOMAP
! NOMAP-NOT: .llvm_bb_addr_map

! RUN: %flang_fc1 -triple riscv64-unknown-linux-gnu -fbasic-block-address-map -emit-obj %s -o - | llvm-readobj --sections - | FileCheck %s --check-prefix=OBJ
! OBJ: Name: .llvm_bb_addr_map
! OBJ-NEXT: Type: SHT_LLVM_BB_ADDR_MAP

subroutine clear_positive(n, x)
  integer :: n, i
  real :: x(n)
  do i = 1, n
    if (x(i) > 0) x(i) = 0
  end do
end subroutine
