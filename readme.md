Hi, this is Marcin @hawix (father) and Kuba @qbus (son).

We are members of the [Polish Society for the Protection of Technical Heritage (PTODT)](https://ptodt.org.pl/). From time to time, we manage to bring old computers back to life. It's our shared passion. We spend time together and learn about electronics, computer science, computer system architecture, and their history. 

We summarize the results of our work at events organized by PTODT, called KWAS.

---

In 2025, Kuba received an iconic **Compaq Portable III** computer from one of the society members, Szymon. The computer was complete, but its plasma screen was broken.

We decided to resurrect this computer. 
The project presented here is the result of our work. The broken plasma screen is beyond repair, but we came up with the idea of ​​replacing the screen with a modern LCD screen with an HDMI connector. 

To achieve this, we analyzed the signals reaching the display. We designed a simple FPGA-based circuit that decodes signals and converts them into an HDMI stream.

---

On Saturday, June 26, 2025, the 40th KWAS meeting took place in Katowice, where we presented our joint adventure of restoring a donated computer. 
**[You can watch it here]** *(Note: insert video link here)*. There, we discuss how it works.

We know that many Compaq Portable III computers experience screen problems for various reasons. We hope this project will help bring your computer back to life.

### We are sharing all project files:

* 📁 **`fpga-tang-nano`**  
  Verilog source code for the Tang Nano 9K platform. This is a very inexpensive circuit with a low entry threshold for amateurs. The FPGA configuration is written in the [Gowin IDE](https://www.gowinsemi.com/en/support/home). You can build a bitstream for this circuit yourself and transfer it to the flash memory via USB-C.

* 📁 **`Schematics-kicad`**  
  Schematic of a board with a voltage converter from 5V logic signals from the Compaq to the 3.3V logic required by the Tang Nano. The board is designed as a shield that attaches to the back of the Tang Nano 9K to minimize space and fit inside the display case. It also includes a USB connector for powering the display. The catalog also includes ready-made Gerber files, which you can submit to PCBWay or similar companies.

* 📁 **`adapter-fussion360`**  
  3D printable LCD screen adapter design.