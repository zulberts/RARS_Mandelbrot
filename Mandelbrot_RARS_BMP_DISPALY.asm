.data
base_address: .word 0x10010000
width:        .word 512
height:		.word 512
max_iter:     .word 255
promien:      .word 4098

.text
.global main
main:
    la s0, base_address
    la s2, max_iter
    lw s2, 0(s2)
    la s3, promien
    lw s3, 0(s3)
    la s4, width          
    lw s4, 0(s4)
    mv s1, s4          
    slli s4, s4, 2
    la s10, height
    lw s10, 0(s10)         
outer_loop:
    mv s5, s10
inner_loop:
    jal scale_complex
    jal iteration
    jal choose_color
    addi s5, s5, -1
    bnez s5, inner_loop
    addi s1, s1, -1
    bnez s1, outer_loop
    li a7, 10
    ecall

scale_complex:		# poprawne skalowanie dla 512x512
	# uzywam (2024 to 2.0)
    mv t1, s1
    mv t2, s5
    slli t1, t1, 3       
    sub t1, t1, s4
    slli t2, t2, 3
    sub t2, s4, t2
    mv t3, t1
    mv t4, t2
    li s11, 0
    addi s11, s11, 1
    ret
iteration:
    mul t5, t3, t4
    srai t5, t5, 10
    slli t5, t5, 1
    mul t6, t3, t3
    srli t6, t6, 10
    add t3, t5, t1

    mul t5, t4, t4
    srai t5, t5, 10
    sub t4, t5, t6
    add t4, t4, t2

    mul t5, t4, t4
    srai t5, t5, 10
    mul t6, t3, t3
    srai t6, t6, 10
    add a4, t6, t5
    addi s11, s11, 1
    mv a6, s11
    bge a4, s3, next
    blt s11, s2, iteration
next:
    ret
    
choose_color:
    li t5, 25
    li t6, 255
    mul t5, t5, s11
    sub a5, t6, t5
    blez a5, zero_color

    slli t5, a5, 16
    slli t6, a5, 8
    or a5, t5, t6
    or a5, a5, a5

write_color:
    sw a5, 0(s0)
    addi s0, s0, 4
    ret

zero_color:
    li a5, 0
    j write_color

