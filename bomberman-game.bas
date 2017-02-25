' bomberman.bas - textbasierter Bomberman Klon in FreeBasic
#LANG "fb"

' Variablen und co.
dim Dateiname as string
dim taste as string = ""

dim as integer x = 0
dim as integer y = 0 
dim as integer tmp = 0
dim as boolean ende = FALSE

dim as integer x_alt = 0
dim as integer y_alt = 0

const as string FREI = " "
const as string FIGUR = "o"
const as string WAND = "#"
const as string BOMBE = "*"
const as string FIGUR_TOD = "@"
const as string FIGUR_LEGT_BOMBE = "O"

dim as integer start_x = 0
dim as integer start_y = 0

dim as integer max_bomben = 3
dim as integer bomben = 0

type Explosion
	as integer pos_x
	as integer pos_y
	as double start_zeit
	as double abwarte_zeit
	as double endzeit
end type

dim start_bombe(0 to 2) as Explosion

' Funktionen und SUBs
declare sub zeigeWelt(welt() as string)
declare function canMove(welt() as String, x as integer, y as integer) as boolean
declare function bewegeSpieler(welt() as string, x as integer, y as integer, alt_x as integer, alt_y as integer) as boolean
declare sub spielende()
declare sub abwarten(wartezeit as double)
declare function ladeKarte(datei as string, welt() as string, byref start_x as integer, byref start_y as integer) as boolean

' Karte die geladen werden soll eingeben
Dateiname = "karte01.txt"

dim welt(any, any) as string

if not ladeKarte(Dateiname, welt(), start_x, start_y) then
	print !"\34!!!FEHLER!!! beim laden der Datei\34"
	end
endif


color 3, 0 ' Spiel in einen schönen blau darstellen :-)
cls
zeigeWelt(welt())

' Spieler auf aktuelle Position in der Welt setzen
y = start_y
x = start_x

' Cursor unsichtbar machen
locate , , 0

' Hauptschleife
do
	taste = INKEY

	' Tastatur abfragen und Spieler bewegen
	select case taste
		case "w"
			if bewegeSpieler(welt(), x, y-1, x, y) then
				y = y - 1
			end if
			zeigeWelt(welt())

		case "s"
			if bewegeSpieler(welt(), x, y+1, x, y) then
				y = y + 1
			end if
			zeigeWelt(welt())

		case "a"
			if bewegeSpieler(welt(), x-1, y, x, y) then
				x = x - 1
			end if
			zeigeWelt(welt())

		case "d"
			if bewegeSpieler(welt(), x+1, y, x, y) then
				x = x + 1
			end if
			zeigeWelt(welt())

		case chr(32)
			' Bombe legen mit der Leertaste 
			'
			if (max_bomben > bomben) and (welt(y, x) <> BOMBE) then
				welt(y, x) = FIGUR_LEGT_BOMBE ' Spieler legt die Bombe
				zeigeWelt(welt())

				' alte Postion von Spieler speichern um festzustellen
				' ob der Spieler sich noch an der Bombe befindet
				'
				x_alt = x
				y_alt = y

				welt(y, x) = BOMBE ' Bombe legen				

				' aktuelle Informationen über Bombe zwischen speichern
				'
				start_bombe(bomben).pos_x = x
				start_bombe(bomben).pos_y = y
				start_bombe(bomben).start_zeit = timer
				start_bombe(bomben).abwarte_zeit = 3.0

				bomben = bomben + 1
			end if

		case chr(27)
			' Bei Esc-Taste Spiel beenden
			'
			ende = TRUE
	end select

	' !!!Variablen anzeigen zum debuggen!!!
	locate 13, 35
	print "bomben: "; bomben

	locate 14, 35
	print "tmp: "; tmp

	' Aktionen steuern
	select case bomben
		case 1
			tmp = 0

		case 2
			tmp = 1

		case 3
			tmp = 2
	end select

	' Wenn min. eine Bombe aktiv ist dann
	' Bombenwartezeit aktuell halten
	'
	if bomben <> 0 then
		start_bombe(0).endzeit = timer
		start_bombe(1).endzeit = timer
		start_bombe(2).endzeit = timer
	end if

	' Abfragen ab welchen Zeitpunkt eine Bombe hochgehen soll und was dann zu tun ist
	'
	if (bomben > 0) and ( start_bombe(tmp).endzeit > ( start_bombe(tmp).start_zeit + start_bombe(tmp).abwarte_zeit ) ) then
		' Bombe zurücksetzen
		'
		bomben = bomben - 1

		if (welt(y, x) = BOMBE) and (x_alt = x) and (y_alt = y) then
			welt(start_bombe(tmp).pos_y, start_bombe(tmp).pos_x) = FIGUR_TOD
			ende = TRUE ' Spielbeenden
		else
			welt(start_bombe(tmp).pos_y, start_bombe(tmp).pos_x) = FREI
		end if

		zeigeWelt(welt())
	end if

	sleep 1
loop until ende = TRUE ' Solange durchlaufen bis das Spiel beendet wird

' Spielende
spielende()
end

' Soll einfach nur die Welt auf dem Bildschirm ausgeben
'
sub zeigeWelt(welt() as string)
	dim as integer j, k

	' Bildschirm Position zurücksetzen
	locate 1, 1

	for j = lbound(welt,1) to ubound(welt,1)
		for k = lbound(welt,2) to ubound(welt,2)
			print welt(j, k);
		next
		print
	next
end sub


function canMove(welt() as String, x as integer, y as integer) as boolean
	if y < lbound(welt,1) or y > ubound(welt, 1) then return false
	if x < lbound(welt,2) or x > ubound(welt, 2) then return false

	if welt(y, x) = WAND then return false
	if welt(y, y) = BOMBE then return false

	return true
end function



' Soll den Spieler bewegen und Eingaben überprüfen ob Sie gültig sind
' und abfragen ob man gegen ein Objekt läuft usw
'
function bewegeSpieler(welt() as string, x as integer, y as integer, alt_x as integer, alt_y as integer) as boolean

	if not canMove(welt(), x, y) then return false

	if (welt(y, x) = FREI) or (welt(y, x) = FIGUR) then
		welt(y, x) = figur ' Spieler platzieren

		' alte Spieler Position löschen, wenn keine Bombe gelegt wurde
		if welt(alt_y, alt_x) <> BOMBE then welt(alt_y, alt_x) = FREI

		return true
	end if
	
	return false
end function

' Soll einfach einige Dinge erledigen nach dem das Spiel vorbei ist
'
sub spielende()
	abwarten(1.0)
	cls
	print "Danke fürs spielen :-)"
end sub

' wartet eine übergebene Wartezeit in Sekunden ab...
'
sub abwarten(wartezeit as double)
	dim as double zeit = 0.0

	zeit = timer

	do
	loop until timer > zeit + wartezeit
end sub



function ladeKarte(Dateiname as string, welt() as string, byref start_x as integer, byref start_y as integer) as boolean
	dim daten as string
	dim as integer zeilen, spalten
	
	' Welt laden
	dim DateiNr as integer = FreeFile
	if open(Dateiname for binary as #DateiNr) = 0 then
	
		daten = space(lof(DateiNr)) ' Dateigröße ermitteln
					    ' und mit Leerzeichen füllen
	
		get #DateiNr, , daten ' aktuelles Zeichen in daten speichern
	
		close #DateiNr
	else
		return false
	end if
	
	' Weltgröße ermitteln
	spalten = instr(daten, any !"\r\n")-1
	zeilen = len(daten) \ (spalten + iif(daten[spalten] = asc("\r"), 2, 1))
	
	' Karte laden und in Array speichern
	redim welt(0 TO zeilen-1, 0 TO spalten-1) as string
	
	dim as integer x, y
	for i as integer = 0 to len(daten)-1
		if daten[i] = 10 then
			y += 1
			x = 0
			continue for
		end if
		if daten[i] = 13 then continue for
		
		welt(y, x) = chr(daten[i])
		
		' Aktuelle Spieler Position feststellen
		if welt(y, x) = figur then
			start_x = x
			start_y = y
		end if
		
		x += 1
	next
	
	return true
end function
