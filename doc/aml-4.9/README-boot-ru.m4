changequote(<<,>>)dnl
changecom(`', `')dnl
Что это?
--------

Это модифицированное ядро для Android TV приставки PLATFORM.
Список модификаций по сравнению со стоковым ядром можно найти
в файле CHANGES-ru.txt.


Как загрузить
-------------

Скопируйте все файлы из каталога, соответствующего Вашей модели
(2G для моделей с 2Гб памяти, 3G для моделей с 3Гб памяти и т.д.).
на USB флэшку или SD карту. Вставьте её в соответствующий разъём.

Теперь нажмите зубочисткой или спичкой кнопку внутри разъёма AV,
отключите разъём питания и вставьте его обратно. Держите кнопку
нажатой достаточно долгое время. Если Ваша флэшка с лампочкой,
Вы определите момент, когда можно отпустить, по миганию флэшки -
пошла загрузка с неё.

После первой удачной загрузки в дальнейшем приставка всегда будет
пытаться загрузить модифицированное ядро с USB или SD карточки.
Чтобы вернуться на исходное ядро, просто вытащите картофлэшку.

Также после загрузки в режиме восстановления (TWRP или стоковое recovery)
приставка сбрасывает автозагрузку с картофлэшки. Чтобы восстановить
автозагрузку, нужно опять один раз загрузиться с помощью спички.


Какое ядро загружено?
---------------------

Вы можете определить, какое ядро загружено (стоковое или модифицированное) по:

* начальной анимации 'boot'
* содержимому дисплея (мод. ядро показывает время/дату/температуру процессора)
* выводу команды 'uname -r', например, с компьютера:
    > adb connect 192.168.1.253 # IP адрес Вашего PLATFORM
    > adb shell uname -r
