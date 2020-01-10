#RISC-V CPU

> 陆嘉馨 
> 518030910412

### 我的设计

##### 五级流水

CPU 以五级流水的方式进行并行。

- IF
  获得指令。从pc_reg中获得pc，从mem_ctrl中获得指令inst，连接btb，同时从btb中获取分治预测的信息。

- ID
  Decode the inst and data forwarding. 从 ex 和 mem 处进行 Data forwarding. 和《自己动手写CPU》中不一样的是，选择在ex阶段再进行 branch 的 target 判断操作。

- EX
  根据 decode 的结果进行运算。Branch对应的判断在ex中进行。

- MEM
  读写操作。与 mem_ctrl 进行交互，获得读写操作的结果。

- regfile
  进行 register 相关的操作，最后的 write back 也在这里进行。

- mem_ctrl
  与助教所提供的接口直接相接，根据 if 和 mem 阶段发来的需求进行数据的读写。从助教所给的接口中读 32bit 的数据需要 6 个周期，写入 32bit 的数据需要 4 个周期。
  同时 mem_ctrl 也负责和 icache 对接，给 cache 提供进行 replace 的指令以及根据 mem_ctrl 所给的 pc 获得对应 inst, 判断一个 pc 是否在 cache 中 hit 会在第一个周期内就完成。

- cache
  cache.v 文件中仅是一个 1-way 仅进行读写操作的cache。而在 mem_ctrl 中实现了 2-way set association 的 cache 结构。

- pc_reg
  获得 pc 和 npc。和 if、mem_ctrl 相连，给其所需要的 inst 地址信息。同时要考虑 ex 阶段 branch 判断的结果。

- stall_ctrl
  对所有遇到的 stall 申请进行汇总判断并给出 stall 指令，同时还要针对 branch 命令对 if/id 和 id/ex 中传递数据进行控制。

- pred
  一个有 btb 的predictor. 对 pc_reg 给出的 pc 进行预测，对 ex 中给出的 branch 判断结果更新predictor.

- if_id, id_ex, ex_mem, mem_wb
  在对应两个阶段之间进行数据的传递，利用时序电路分割五级流水。

#### 一些特点
- Cache
  iCache 采用 2-way set association 的设计可以大大提高 cacheHit 率，加快运行时间。对于同一个 entry 从 cache valid 位判断 replacement 需要对哪一路进行， replacement 发生在从 memory 读入一个 inst 完成以后。

- BTB
  利用 2-bit history table 进行分支预测，结合 branch target buffer 使得其可以马上获得预测的地址，在分治预测正确的情况下可以节省 2 个周期的时间。
  2-bit history table 采用传统的判断方式，初始值均设为 2'b10 (weak taken).
  BTB的更新来源于 ex 遇到 branch 指令后做出的关于 jump addr 和 taken/not taken 的判断。
  BTB的结构类似于 icache，tag 对应 icache 中的 tag, 记录的地址对应 icache 中记录的 inst，而 icache 的 valid 位则对应 2-bit history table 中的判断。

- FPGA 上板
  含有 BTB 版本的CPU并没能成功在FPGA板上跑出结果，因此我上板的是 predictor 不起作用的版本的CPU，即有 icache 版本的 CPU。进行过升频的尝试但由于升到 101MHz 就有很大的 WNS 因此没有继续。
  pi 的运行时间 0.60s, 结果如图.
  其余测试点均已通过。
  
  ![avatar](https://github.com/Jiaxin-Lu/RISCV-CPU/blob/master/doc/pi_fpga0.6.jpg)

  特别感谢傅凌玥同学帮助我进行了上板的测试，测试过程在傅凌玥同学的电脑上进行，结果图来源于其截屏。

---

## 主要问题和解决

#### 最基础的版本

第一个版本的代码仅有五级流水，并且memory的读写效率非常低下，在加入cache以后在gcd上出现问题，故直接遭遇抛弃进行重构。
带 cache 一起重构后通过了 cache 相关的测试点，但是在加入 branch predictor 的时候依然出现了gcd中和最早的版本一样的问题。
最后发现是在 data forwarding 的过程中没有考虑到0号寄存器实际值应为0的情况导致即将写入0号寄存器的非0的值被直接传回了id，导致获取到了错误的 data forwarding 的值，而这一错误恰好是运行速度快使得流水线产生作用后导致的。
而这一问题一直藏在最基础的结构中直到在 branch predictor 加入后才被发现，可见流水线运行对数据传递精准性的要求。

#### icache版本

除了一开始加入 icache 产生了后来被解决的gcd相关的问题（猜测原因其实也是0号寄存器相关），icache版本在本地 simulation 中表现稳定。

#### branch prediction 版本

加入BTB的版本是调试时间最长的版本。一个是因为最基础的版本中之前因为运行速度慢而被忽略的错误可能直到此时才被发现。另一个是加入 branch predictor 之后需要和 if、ex 等模块进行协调，同时还需要 if和pc_reg 之间等进行协调。因而在调试过程中产生了大量的问题。
同时由于BTB的加入，ex阶段对 branch 的判断也变得复杂，判断方式总共进行过 3 次大的修改。有一次甚至是因为 reg1、reg2 的值为`XXXXXXXX`导致实则无法进行 Branch 的判断，但代码中未考虑到这一点而直接判断预测地址是否和给出的 jmp_target 一致导致进行了错误的判断。而这个错误其实反而是在先前的错误修正过程中产生的。而且这也是因为运行速度加快、指令变得紧凑导致的。

#### FPGA 版本

上板过程中遇到很多困难，上板之后的调试几乎无法进行。
BTB版本的代码在 vivado 上已经正确进行了 Synthesis、Implementation、Generate Bitstream 的步骤但是最后却无法在FPGA上运行。而且 Synthesis 时已经排除了所有的 latch 等错误，只能因此放弃。
故考虑更为简单的icache版本上板，主要依靠 pi 这一测试点进行速度的测试，100MHz 下达到 0.6s 的速度，略微尝试了一下升频（但是在101Mhz下就有很大的WNS所以无法进行更好的升频了，猜测原因是 Cache 在一个周期内hit延迟很大），在 101MHz 下速度略微变快。
虽然 icache 版本上板能跑，但是依然有很多问题亟需解答。

---

## 总结

#### 一些总结

整个CPU的过程中调试占用了大量的时间，并且效率很低，往往需要对比大量的波形图才能找到问题的所在。vivado软件效率较低，使用上也有很多不方便之处，对调试工作也带来了很大的影响（很多时间都花在等待vivado运行上）。
在整个过程中我经历了一次大型的重构，原因在于自己的mem_ctrl效率问题和调试icache时失去理想。而在重构的过程中，很多部分其实并没有什么改变，但也在很多地方的处理上尽量做到了精简。
从过程中也感受到提前做好规划和设计的重要性，这样可以提高代码的可靠性。同时，应该提前计算好节拍和对应操作（尤其在mem_ctrl中）这样才能更高效得利用时间。
在阅读波形图的时候，可以一开始先观察波形特点，找到可能的一些死循环或者数据出错的地方，再进行放大对其前后进行比较。同时还可以利用历史版本中跑出正确结果的波形图进行对比找到数据错误的地方。看波形图其实就类似于调试其他程序时的逐步执行。
整个项目我自己前期大多一个人闷头干，所以进展非常慢，很晚才开始迈出第一步并且绕了很多弯路，与一些经常讨论的同学拉开了差距。直到最后才问了同学一些问题，也多和FPGA有关并且很多并没有获得解决。整个过程中还是应该多多参与一些讨论，有些操作也只能多问才能掌握。

#### 一些建议

还是比较建议助教尽早公布给分方式，这样才能让我们更加安心地写大作业，而不是在最后的时间里不断加一些功能。这样也会恶化同学之间的竞争。
希望助教能给出关于vivado、调试、FPGA上板的更为详尽的文档资料等，这样能让大家在无人帮助的情况下更快上手（不是所有同学都能有参与讨论的时间和资源）。
对于一些书上没有的部分（cache，branch predictor等等），也希望能有提供一些参考学习的资料。作为初次尝试，很可能把一个简单的操作复杂化（比如我在写branch predictor的时候一开始进行了大量的分类讨论，后来发现其实并不需要如此复杂考虑，有些看起来很复杂的结构其实可以舍弃掉一些复杂的部分，其效率并不会下降很多）。
有一部分测试数据其实是无法在Vivado上跑的（比如有 sleep 的程序），也希望能提前说一下，之前在这上面浪费了半天的调试时间才被告知这一点。

