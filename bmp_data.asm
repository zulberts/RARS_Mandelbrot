	.data
	.eqv    FileHeaderSIZE 14
	.eqv    InfoHeaderSIZE 40
BitMapFileHeader: .space 14
headerbreak:	  .space 2
BitMapInfoHeader: .space 40
	.eqv    bfTableStart 10
	.eqv    biWidthStart 4
	.eqv    biHeightStart 8
	.eqv    biTableSizeStart 20
