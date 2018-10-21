


INCLUDE Irvine32.inc
INCLUDE macros.inc


BUFFER_SIZE = 501;// maks velicina

.data

buffer BYTE BUFFER_SIZE DUP(? )
filenameout BYTE "output.txt", 0
filename BYTE 80 DUP(0)
fileHandle HANDLE ?
u BYTE 501 DUP(? )
enc_or_dec BYTE ?
k DWORD ?
p DWORD ?
stringLength DWORD ?
s DWORD ?
v DWORD ?
i DWORD ?
n DWORD ?
uk DWORD ?
r DWORD ?
l DWORD ?
m BYTE ?
z DWORD 501 DUP(0)

str1 BYTE "Cannot create file", 0dh, 0ah, 0
outHandle HANDLE 0
bytesWritten DWORD ?
endl EQU <0dh, 0ah>;// end of line
novired LABEL BYTE
BYTE endl


.code
main PROC
; UCITAVANJE FILE - a

mWrite "Unesite ime file-a: "
mov edx, OFFSET filename
mov ecx, SIZEOF filename
call ReadString
; Open the file for input.
mov edx, OFFSET filename
call OpenInputFile
mov fileHandle, eax
; Check for errors.
cmp eax, INVALID_HANDLE_VALUE; error opening file ?
jne file_ok; no: skip
mWrite <"Cannot open file", 0dh, 0ah>
jmp quit; and quit

file_ok :
; Read the file into a buffer.
mov edx, OFFSET buffer
mov ecx, BUFFER_SIZE
call ReadFromFile
jnc check_buffer_size; error reading ?

poruka :
	mWrite "Error reading file. "; yes: show error message
	call WriteWindowsMsg
	jmp close_file

	check_buffer_size :
cmp eax, BUFFER_SIZE; buffer large enough ?
jb buf_size_ok; yes
mWrite <"Error: Buffer too small for the file", 0dh, 0ah>
jmp quit; and quit


buf_size_ok :
mov ecx, eax
mov stringLength, eax
mov uk, ecx
mov ebx, 0
mov al, [buffer + ebx]; ucitava prvo slovo
mov enc_or_dec, al
add ebx, 1; preskace razmak
mov p, eax
mov eax, uk
sub eax, 2
dec eax
mov uk, eax
mov eax, 0; 

; citanje broja

mov edi, 0

broj :
add ebx, 1; pokazuje na trenutni
mov eax, 0
mov al, [buffer + ebx]; cita ga

mov p, eax
mov eax, uk
sub eax, 1
mov uk, eax
mov eax, p
cmp al, 0ah; EOF
je poruka; ako nema teksta
cmp al, 0dh; EOL
je kraj_linije
imul edi, 10
sub al, 48
add edi, eax
mov n, edi
jmp broj

; pocetak ucitavanja teksta za obradu
kraj_linije :
add ebx, 1
mov r, ebx;
mov edx, 0
sub ecx, 1
mov l, ecx
mov i, 0
loop1 :
	add ebx, 1
	mov al, [buffer + ebx]
	mov m, ' '
	cmp m, al; izbacuje razmak ako dobijemo tekst za sifrovanje
	je loop2
	mov edx, i
	mov[u + edx], al
	mov cl, [u + edx]
	mov eax, i
	add eax, 1
	mov i, eax

	jmp loop3
	loop2 :
mov eax, stringLength
sub eax, 1
mov stringLength, eax
mov eax, uk
sub eax, 1
mov uk, eax
loop3 :

cmp l, ebx
jne loop1
mov ecx, l
add ecx, 1
mov edx, n

; pocetak izracunavanja koliko koji red ima slova
mov eax, uk
mov eax, 2
mul edi
sub eax, 2; k je koliko ima slova u jednom ciklusu
mov k, eax
mov ecx, k
mov eax, uk
mov s, 0
div ecx; broj celih ciklusa
mov p, eax; broj celih ciklusa
mul ecx
mov l, eax; ukupan broj slova u punim cilkusima
mov i, 0
mov edi, 0
mov eax, n
sub eax, 1
mov v, eax
mov ecx, 0

mov eax, p
mov[z + ecx], eax

mov eax, l
inc eax
cmp uk, eax
jb  pon1; ako je carry 1 uk je vece od l
mov eax, [z + ecx]
add eax, 1

mov[z + ecx], eax
mov eax, s
inc eax
cmp eax, n
je sif_ili_desif
dec eax
mov s, eax

pon1 : ; posle prvog reda svaki se tu vraca
	add ecx, 4
	mov eax, s
	add eax, 1
	mov s, eax
	cmp v, eax
	je loo

	mov eax, 2
	mov edx, p

	mul edx
	mov[z + ecx], eax
	mov eax, l
	inc eax
	add eax, s
	cmp uk, eax
	jb pon1
	mov eax, [z + ecx]
	add eax, 1
	mov[z + ecx], eax
	mov eax, l
	inc eax
	add eax, k
	sub eax, s
	cmp uk, eax
	jb pon1
	mov eax, [z + ecx]
	add eax, 1
	mov[z + ecx], eax

	jmp pon1

	loo :
mov eax, p

mov[z + ecx], eax
mov eax, l
add eax, n
cmp uk, eax
jb sif_ili_desif
mov eax, [z + ecx]
add eax, 1
mov[z + ecx], eax




sif_ili_desif :
cmp enc_or_dec, 'e'
je sifrovanje
cmp enc_or_dec, 'd'
je desifrovanje

greska :
mWrite <"Pogresni zahtevi", 0dh, 0ah>
jmp quit

sifrovanje :
mov[buffer + 0], 'd'
mov s, 0
mov i, 0

mov eax, 0
mov edi, 0
mov ecx, 0
mov ebx, r
add ebx, 1
pon2 :
	mov al, [u + ecx]
	mov[buffer + ebx], al
	add ebx, 1
	add ecx, k
	mov eax, i
	add eax, 1
	mov i, eax
	cmp[z + edi], eax
	jne pon2; kraj n = 1

	pon3 :; sledeci red se sifruje
	add edi, 4
	mov eax, s
	mov ecx, 0
	mov i, 0
	inc eax
	mov v, 0
	mov s, eax
	inc eax
	cmp eax, n;
je loop5

pon4 :
mov ecx, v	; zadrzavamo vrednost jer nam je potrebno, ostalo sve radimo preko v
add ecx, s
mov al, [u + ecx]
mov[buffer + ebx], al
add ebx, 1
mov eax, i
add eax, 1
mov i, eax
cmp eax, [z + edi]
je pon3
mov ecx, v
add ecx, k
mov v, ecx
sub ecx, s
mov al, [u + ecx]
mov[buffer + ebx], al
mov eax, i
add eax, 1
mov i, eax
add ebx, 1
cmp eax, [z + edi]
je pon3
jmp pon4
loop5 :
mov ecx, n
sub ecx, 1
mov eax, 0
pon5 :	;  poslednji red se sifruje

mov al, [u + ecx]
mov[buffer + ebx], al
mov eax, i
add eax, 1
mov i, eax
add ebx, 1
add ecx, k
cmp eax, [z + edi]
jne pon5
mov[buffer + ebx], 0ah
jmp ispis


desifrovanje :
mov[buffer + 0], 'e'
mov i, 0
mov s, 0
mov p, 0
mov s, 0
mov ecx, 0
mov eax, 0
mov edi, 0
mov ebx, r
add ebx, 1
mov r, ebx

;desifrovanje prvog reda
lp:
mov al, [u + ecx]
mov[buffer + ebx], al
add ecx, 1
mov eax, i
add eax, 1
mov i, eax
add ebx, k

cmp eax, [z + edi]
jne lp
mov eax, s
inc eax
cmp n, eax
je ispis	;kraj_desifrovanja

lp1:
add edi, 4
mov eax, s
inc eax
mov s, eax
inc eax
mov ebx, r
mov i, 0
cmp eax, n; edx treba da bude n - 1, ovde se skace da treba poslednji red da se sifruje
je lp3
mov eax, 0
lp2:
mov v, ebx
add ebx, s
mov al, [u + ecx]
mov[buffer + ebx], al
mov eax, i
add eax, 1
mov i, eax
add ecx, 1
cmp eax, [z + edi]
je lp1
mov ebx, v
add ebx, k
mov v, ebx
sub ebx, s
add eax, 0
mov al, [u + ecx]
mov[buffer + ebx], al
add ecx, 1
mov eax, i
inc eax
mov i, eax
cmp eax, [z + edi]
je lp1
mov ebx, v
jmp lp2

lp3 :
mov eax, 0
mov ebx, r
add ebx, s
lp4 : mov al, [u + ecx]
	mov[buffer + ebx], al
	add ecx, 1
	mov eax, i
	inc eax
	mov i, eax
	add ebx, k
	cmp eax, [z + edi]
	jne lp4
	;kraj_desifrovanja

ispis :

; Create a new text file
mov edx, OFFSET filenameout
call CreateOutputFile
mov fileHandle, eax
; Check errors.
cmp eax, INVALID_HANDLE_VALUE;  error found ?
jne file_ok1; no: skip
mWrite <"Ne moze se ispisati izlazni fajl", 0dh, 0ah>
jmp quit
file_ok1 :
mov eax, fileHandle
mov edx, OFFSET buffer
mov ecx, stringLength
call WriteToFile
mov bytesWritten, eax; save return value
call CloseFile

jmp quit
close_file :
mov eax, fileHandle
call CloseFile

quit :
invoke ExitProcess, 0
main ENDP
END main

