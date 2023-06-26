# ROI
Project to work

![ROI project scheme](https://github.com/Temix707/ROI/blob/master/scheme/IMG20230622005151.jpg)

![ROI project scheme](https://github.com/Temix707/ROI/blob/master/scheme/IMG_20230627_022236.jpg)

![ROI project scheme](https://github.com/Temix707/ROI/blob/master/scheme/IMG_20230627_022156.jpg)

ПРОЕКТ ROI (Region of Interest)

Набор AXIS Stream
- Входные сигналы AXIS: clk_i, arst_i, tdata_i, tvalid_i, tlast_i (последний кусок данных БолКв) 

- Выходные сигналы AXIS:  tdata_o, tvalid_o, tlast_o (последний кусок данных для МалКв)

—————————————————

Что делает AXIS блок:
- На входе AXIS поток.
- На выходе AXIS поток.

- Параметром задаем Большую область (800 на 600)

- Передаются пиксели в каждом такте.
- Для отображения области задается два параметра - ширин и высота (800 на 600).
- По AXIS передаются строчки по-пиксельно, каждый tvalid_i это 1 пиксель и так передается все изображение.

—————————————————

Что делает APB блок:
- В APB задаем два регистра ([31:0] xy_0_o, xy_1_o), которые отвечают за  координаты двух точек, которые вырисовывают квадрат (600 на 200 и 200 на 400).  
- APB обеспечивает для внешнего процессора управление AXIS блоком.
- В адресах обращаюсь к двум регистрам, то есть: 

(Блок, который ставим в систему и говорим, что нам нужно вырезать пиксели от сюда до сюда, на выходе он дает только выделенную область, а всю остальную выкидывает (то есть опускает tvalid = 0 на выходе) )

—————————————————

Что делает ROI:
- Он должен вырезать изображение и подать наружу кусок изображения внутри.
