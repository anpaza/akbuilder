changequote(<<,>>)dnl
changecom(`', `')dnl
Разница между модифицированным ядром и стоковым ядром для PLATFORM:

  * Модифицированное ядро основано на исходниках от AMLogic версии 4.9.113.
    Стоковое ядро имеет версию 4.9.76.

ifelse(PLATFORM, <<X96max>>, <<dnl
  * Драйвер LED дисплея (под названием 'vfd') был написан с нуля, т.к. исходники
    от AMLogic не содержат драйвер для этого дисплея. Этот драйвер намного более
    продвинут, чем драйвер в стоковом ядре.

    Для отображения информации на дисплее используется демон vfdd. Он автоматически
    запускается при загрузке модифицированного ядра (он находится в файле boot*.img).

    В текущей конфигурации демон vfdd отображает на LED дисплее последовательно
    текущее время (9 сек), затем дату в формате "месяц день" (например, 05 09 - 9 Мая),
    затем текущую температуру процессора в градусах. Также для отображения обращений
    к носителям информации используются индикаторы:

        USB     отображает чтение с USB носителя
        APPS    отображает запись на USB носитель
        CARD    отображает чтение с внутренней микросхемы памяти
        SETUP   отображает запись на внутреннюю микросхему памяти
        HDMI    отображает состояние HDMI

    Исходные тексты этого драйвера и демона можно скачать с GitHub:
    https://github.com/anpaza/linux_vfd

    Конфигурационный файл демона vfdd называется /vfdd.ini. Если Вы хотите внести
    в него изменения, скопируйте его в каталог /etc/ и там изменяйте. При следующей
    перезагрузке vfdd автоматически подхватит файл /etc/vfdd.ini.
>>)dnl

  * Добавлены модули поддержки файловых систем NFS и SMB. Чтобы их использовать,
    Вам понадобятся соответствующие утилиты. Эта работа пока не закончена.

  * Добавлены модули ядра cp210x.ko, pl2303.ko, ch341.ko, ftdi_sio.ko, предназначенные
    для USB-UART переходников, использующихся для связи с простыми устройствами, типа
    поделок на Ардуино и т.п. Так как udevd в Андроиде отсутствует, Вам придётся загружать
    нужный драйвер вручную, добавив скрипт в /etc/init.d/ с командой

        modprobe cp210x.ko (или pl2303.ko и т.п.)

dnl  * Включена поддержка жёстких дисков, разбитых в формате Windows Dynamic Disks.
dnl    Подробно про использование динамических дисков:
dnl    https://4pda.ru/forum/index.php?showtopic=773971&view=findpost&p=62595635
dnl
dnl  * По умолчанию отключён аппаратный шумодав, из-за которое на тёмных сценах можно наблюдать
dnl    "мыльный шлейф" (/sys/module/di/parameters/nr2_en=0).
dnl
  * Добавлена поддержка автоматической смены частоты кадров (auto framerate) при использовании
    аппаратного декодера видео. Для этого был написан демон afrd, который запускается при старте
    системы и реагирует на сообщения ядра о начале или окончании проигрывания видео. Также были
    модифицированы практически все аппаратные декодеры видео, т.к. уведомления о смене частоты
    дисплея в настоящий момент там жёстко поломаны.

    Файл конфигурации демона /afrd.ini, если хотите его изменить - скопируйте его в /etc/afrd.ini,
    если демон найдёт этот файл он будет использоваться вместо /afrd.ini.

    Исходные тексты этого демона можно скачать с GitHub:
    https://github.com/anpaza/afrd