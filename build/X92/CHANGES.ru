Разница между модифицированным ядром и стоковым ядром для X92:

  * Модифицированное ядро основано на исходниках от AMLogic от 10 марта 2017.
    Стоковое ядро основано на более старых исходниках, примерно октябрь 2016.

  * Драйвер LED дисплея (под названием 'vfd') был написан с нуля, т.к. исходники
    от AMLogic не содержат драйвер для этого дисплея. Этот драйвер намного более
    продвинут, чем драйвер в стоковом ядре.

    Для отображения информации на дисплее используется демон vfdd. Он автоматически
    запускается при загрузке модифицированного ядра (он находится в файле boot*.img).

    В текущей конфигурации демон vfdd отображает на LED дисплее последовательно
    текущее время (9 сек), затем дату в формате "месяц день" (например, 05 09 - 9 Мая),
    затем текущую температуру процессора в градусах. Также для отображения обращений
    к носителям информации используются индикаторы:

        USB - отражает чтение с USB носителя
        APPS - запись на USB носитель
        CARD - чтение с внутренней микросхемы памяти
        SETUP - запись на внутреннюю микросхему памяти

    Исходные тексты этого драйвер и демона можно скачать с GitHub:
    https://github.com/anpaza/linux_vfd
