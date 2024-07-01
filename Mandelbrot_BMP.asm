	.globl main	
	.include "bmp_data.asm"
	.include "complex.asm"	
	.data	
input: 	.asciz  "/Users/skutn/Desktop/ARKO/input.bmp"
output:	.asciz  "/Users/skutn/Desktop/ARKO/output.bmp"
error:	.asciz	"\nCould not open file\n"
	.text
main:
	jal	open_bmp_file
start_iterator:				#niestety bez paddingu (obrazy 4n x 4k)
	mv	t0, s5			# w s5 mamy pointer heapa
	add	t6, s5, s3		# w t6 mamy koncowa dlugosc heapa
	mv	t3, s2			# w t3 mamy wysokosc
	addi	t3, t3, -1		# 
loop_height:
	li	t2, 0			# poczatkowa szeroksc (s1 to szerokosc obrazu)
	bltz	t3, end_loop		# s2 to poczatkowa wysokosc a s3 to total bites
loop_width:
	bge	t2, s1, next_height	# t2 > s1 idziemy do next_height
					# skalowanie rzeczywistej liczby
					# s6 = (x / WIDTH) * (RE_END - RE_START) + RE_START 	
	slli	t2, t2, 16		# uzywam fixed pointa 2^16		
	div	s6, t2, s1
	srai	t2, t2, 16
	li	s8, RE_START
	li	s9, RE_END
	sub	s9, s9, s8
	mul	s6, s6, s9
	slli	s8, s8, 16
	add	s6, s6, s8
					#skalowanie urojonej liczby
					# s7 = (y / HEIGHT) * (IM_END - IM_START) + IM_START
	slli	t3, t3, 16
	div	s7, t3, s2
	srai	t3, t3, 16
	li	s8, IM_START
	li	s9, IM_END
	sub	s9, s9, s8	
	mul	s7, s7, s9
	slli	s8, s8, 16
	add	s7, s7, s8
					#obliczamy czy stabilne czy nie
	jal	mandelbrot	
	li	t4, 255
	slli	s10, s10, 16
	mul	s8, s10, t4	
	li	t5, MAX_ITER
	div	s8, s8, t5
	srai	s8, s8, 16	
	sub	s8, t4, s8

color:					# kolorujemy bity, (niebieski, zielony, czerwony [RGB])
	bge	t0, t6, end_loop
	sb	s8, (t0)
	addi	t0, t0, 1
	bge	t0, t6, end_loop
	sb	s8, (t0)
	addi	t0, t0, 1
	bge	t0, t6, end_loop
	sb	s8, (t0)
	addi	t0, t0, 1	
	addi	t2, t2, 1
	b	loop_width
next_height:
	addi	t3, t3, -1			# liczba rzedow do wypisania aktualizacja
	j loop_height
end_loop:
	jal 	open_destination_file	
	li	a7, 10
	ecall
mandelbrot:					# obliczenia do fraktalu mandelbrota
	li	s8, 0
	li	s9, 0
	li	s10, 0
mandelbrotloop:
	mv	t4, s8				# ^ 8
	mv	t5, s9				# ^ 8
	mul	t4, t4, t4			# ^ 16
	mul	t5, t5, t5			# ^ 16
	add	s11, t4, t5			# ^ 16
	li	t4, 4	
	slli	t4, t4, 16			# ^ 16
	bgt	s11, t4, end_mandelbrotloop	
	li	t4, MAX_ITER
	bge	s10, t4, end_mandelbrotloop
	mv	t4, s8	
	mul	s8, s8, s8			# ^ 16
	mul	t5, s9, s9			# ^ 16	
	sub	s8, s8, t5			# ^ 16
	add	s8, s8, s6			# ^ 16
	li	t5, 2
	slli	t5, t5, 8			# ^ 8
	mul	s9, s9, t5			# ^ 16
	mul	s9, s9, t4			# ^ 24
	srai	s9, s9, 8			# ^ 16
	add	s9, s9, s7			# ^ 16
	srai	s9, s9, 8			# ^ 8
	srai	s8, s8, 8			# ^ 8
	addi	s10, s10, 1
	b mandelbrotloop	
end_mandelbrotloop:
	ret
open_bmp_file:					# czytamy plik BMP ktory jest juz w folderze o jakichs wymairach
	la	a0, input
	mv	a1, zero			# read only tryb
	li 	a7, 1024
	ecall
	li	t0, -1
	beq	a0, t0, open_bmp_error
	mv	s0, a0				# zapisujemy file descriptor
read_headers:
	mv	a0, s0				# zapisujemy fileheder i infoheader
	la	a1, BitMapFileHeader		#56 bajtow w sumie
	li	a2, FileHeaderSIZE
	li	a7, 63
	ecall
	mv	a0, s0				# tutaj rozrozniamy zeby moc zapisac szerokosc i wysokosc
	la	a1, BitMapInfoHeader
	li	a2, InfoHeaderSIZE
	li	a7, 63
	ecall
get_dimensions:
	la	t0, BitMapInfoHeader
	lw 	s1, biWidthStart(t0)		# s1 = szerokosc width
	lw	s2, biHeightStart(t0)		# s2 = wysokosc height
	lw	s3, biTableSizeStart(t0)	# s3 = calkowita liczba bajtow
create_heap:
	mv	a0, s3				# tworzymy heapa ktory ma odpowiednia ilosc bajtow
	li	a7, 9
	ecall
	mv	s5, a0				# s5 = pointer heapa
copy_heap:
	mv	a0, s0				# s0 = file descriptor
	mv	a1, s5				# s5 = heap pointer
	mv	a2, s3				# s3 = ilosc bajtow
	li	a7, 63
	ecall
close_file:
	mv	a0, s0
	li	a7, 57
	ecall
	ret
open_bmp_error:					# plik czesto sie nie otwieral mi to zeby odrazu przerwyalo program
	li	a7, 4
	la 	a0, error
	ecall
	li	a7, 93
	ecall
	ret
open_destination_file:				# otwieramy plik i zapisujemy headery i dane z heapa 
	la	a0, output
	li	a1, 1
	li	a7, 1024
	ecall
	mv	s0, a0
write_headers:
	mv	a0, s0
	la	a1, BitMapFileHeader
	li	a2, FileHeaderSIZE
	li	a7, 64
	ecall
	mv	a0, s0
	la	a1, BitMapInfoHeader
	li	a2, InfoHeaderSIZE
	li	a7, 64
	ecall
write_heap:
	mv	a0, s0
	mv	a1, s5
	mv	a2, s3
	li	a7, 64
	ecall
close_destination_file:
	mv	a0, s0
	li	a7, 57
	ecall	
	ret
	
