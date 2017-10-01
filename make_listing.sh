#!/bin/bash

# Временные файлы
#TEMPFILE='~1.txt'
TEMPFILE=`mktemp -t XXXXXX.txt`
#TEMPPDF='~1.pdf'
TEMPPDF=`mktemp -t XXXXXX.pdf`
#TEMPPS='~1.ps'
TEMPPS=`mktemp -t XXXXXX.ps`


# Вывод дерева файлов
tree --noreport -F -P 'Makefile|makefile|*.h|*.hpp|*.c|*.cpp|*.pl|*.py|*.java|*.sh|*.gpi' >> $TEMPFILE

# Цикл по файлам
#for i in Makefile makefile *.h *.hpp *.c *.cpp *.pl *.py *.java *.sh *.gpi
for i in $(find . -type f \( -name 'Makefile' -o -name 'makefile' -o -name '*.h' -o -name '*.hpp' -o -name '*.c' -o -name '*.cpp' -o -name '*.pl' -o -name '*.py' -o -name '*.java' -o -name '*.sh' -o -name '*.gpi' \) | sort )
do
	if [ -f $i ]
	then
		# Файл обычный
		if [[ $(file -b --mime-encoding $i) =~ utf-8|us-ascii ]]
		then
			# Файл текстовый и в нужной кодировке
			echo >> $TEMPFILE
			# Вывести имя файла во временный файл $TEMPFILE
			# echo -e "\uf0f6 $i:" >> $TEMPFILE
			echo -e "$i:" >> $TEMPFILE

			# Вывести строки из файла во временный файл $TEMPFILE
			# предварённые номерами и с заменой таблуляций на 4 пробела.

			#nl -w3 -ba -s": " $i | sed -e 's/\t/    /g' | sed 's/|/¦/g' >> $TEMPFILE
			#nl -w3 -ba -s". " $i | sed -e 's/\t/    /g' | sed 's/-/–/g' >> $TEMPFILE

			l=$(wc -l < "$i")
			w=${#l}
			fnl=${#i}

			if ((l > 0))
			then
				# Файл не пустой
				r=$((fnl-w))
				# Подчеркнуть имя файла с учётом поля для номеров строк
				printf '%0.s─' $(seq 1 $w) >> $TEMPFILE
				printf '┬' >> $TEMPFILE
				printf '%0.s─' $(seq 1 $r) >> $TEMPFILE
				echo >> $TEMPFILE

				# Заменить табуляции пробелами, добавить в начало номера строк
				#nl -w${w} -ba -s". " ${i} | sed -e 's/\t/    /g' >> $TEMPFILE
				#expand -t4 ${i} | sed -e 's/^    \(\s*\)/¦   \1/g' | sed -e 's/¦    /¦   ¦/g' | nl -w${w} -ba -s"│" >> $TEMPFILE
				expand -t4 ${i} | nl -w${w} -ba -s"│" >> $TEMPFILE
			else
				# Если файл пустой, просто подчеркнуть имя файла
				r=$((fnl+1))
				printf '%0.s─' $(seq 1 $r) >> $TEMPFILE
				echo >> $TEMPFILE
			fi
		fi
	fi
done

# Создать PostScript-файл из текстового,
# набранный заданным шрифтом
paps --font "PT Mono 9" $TEMPFILE > $TEMPPS
#paps --font "Fira Code Medium 8" --lpi 8 $TEMPFILE > $TEMPPS
#paps --font "Nitti Normal 10" --lpi 8 $TEMPFILE > $TEMPPS
#paps --font "Elementa X Bold 10" --lpi 6 $TEMPFILE > $TEMPPS

# Преобразовать его в PDF
ps2pdf $TEMPPS $TEMPPDF

# Удалить временные файлы
rm $TEMPFILE $TEMPPS

# Собрать файлы в архив
find . -type f \( -name 'Makefile' -o -name 'makefile' -o -name '*.h' -o -name '*.hpp' -o -name '*.c' -o -name '*.cpp' -o -name '*.pl' -o -name '*.py' -o -name '*.java' -o -name '*.sh' -o -name '*.gpi' \) -print0 | tar -czvf attachment.tar.gz --null -T -

# Прикрепить архив к листингу
pdftk $TEMPPDF attach_files attachment.tar.gz output listing.pdf

# Удалить временные файлы
rm $TEMPPDF attachment.tar.gz
