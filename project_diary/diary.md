## Woche 1
*[29. Oktober - 5. November]*

**29. Oktober [Meeting mit Johannes]:**
ich habe konzeptionell Leaky Integrate and Fire Modul vorgestellt. Grob: 
```
V_mem (t+1) = V_mem * Zerfallskonstante + I_ext*
V_mem (t+1) > V_threshold?
  - JA: V_mem = 0, Spike = 1
  - NEIN: V_mem = V_mem, Spike = 0

*I_ext wird in einem anderen Modul berechnet, erstmal irrelevant, wo die Daten herkommen.
```
Wir haben vereinbart, dass ich bis naechsten Meeting (13. November, in 2 Wochen):
1. Leaky Integrate and Fire Modullogik schreibe
2. Den mit Testbenches verifiziere (I_ext wird ueber Testbenches gesetzt)

Noch meinte Johannes, dass es spaeter wichtig wird, die Daten von ARM SoC an FPGA zu schicken und hat vorgeschlagen, dass ich jetzt schon versuche das "einzurichten". Deswegen sollte ich noch:
3. Versuchen die Daten auf FPGA von ARM zu laden


### First steps: Einrichten 
Ich habe eine sehr hilfreiche Anleitung zu PYNQ Z2 gefunden!
https://pynq.tue.nl/general/getting-started/

### Verbindung aufbauen
#### manuell IP vergeben
```
IPv4: 192.168.2.24 (*IP des Pynq: 192.168.2.99)
Subnetzmaske: 255.255.255.0
Gateway: 192.168.2.0
DNS:
```
#### ssh
```
Login: xilinx@pynq
Pwd: xilinx
```

#### scp cheatsheet:
```
scp C:\Users\Dascha\Desktop\fpga-pa\pynq\datei.c xilinx@pynq:dascha/datei.c
```

#### PYNQ richtig ausschalten: 
```
1. sudo halt [Linux runterfahren]
2. Schalter OFF
3. Kabel rausziehen
```

#### env (Windows)
Im python_referenzmodell Ordner:
```
python 3.12 -m venv .snn-fpga
.snn-fpga\Scripts\Activate.ps1
pip install -r requirements.txt
```

#### Wichtige Links auf Doku:
- AXI: https://docs.amd.com/r/en-US/pg144-axi-gpio/Introduction
https://docs.amd.com/v/u/en-US/ug1037-vivado-axi-reference-guide
- PYNQ-Z2 Reference Manual: https://www.mouser.com/datasheet/2/744/pynqz2_user_manual_v1_0-1525725.pdf?srsltid=AYCX9vLy_TG5D1ChoYkouw3WfLflT5sgX5-wBN5sKCOHyVdKwESgY1UC



## Woche 2:
*[6. November - 12. November]* bin krank geworden 

- [x] Leaky Integrate and Fire Modul (LIF) mit Delta Synapse geschrieben 
- [x] Bitgenaues Python Modell von LIF Modul
+ [x] LIF Testbench. Funktioniert.

### DATEN UEBER AXI laden
Ich habe:
1. ein Dummy Modul geschrieben, der a + b addiert. 

```
module add_test (
    input  logic        clk,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);
    always_ff @(posedge clk)
        result <= a + b;  
endmodule
```
2. Verilog Wrapper fuers Modul erstellt (da ich anscheinend in Block Design nur .Verilog Bloecke verbinden kann (???))

3. IP Integrate > Create Block Design
Add wrapper, add AXI GPIO
*Idee:* a und b sollen von ARM kommen, das Ergebnis soll zurueck in den Register geschrieben werden
### Generate Bitstream erfolgreich
Wenn Linux auf ARM Chip die Daten zur Laufzeit auf FPGA laedt, brauche ich nur .bit (Bitstream) und .hwh (Hradwarebeschreibung) Datei.

| Datei | Pfad im Projektordner |
| --- | --- |
| Bitstream | <projekt>.runs\impl_1\design_1_wrapper.bit |
| Hardware-Beschreibung | <projekt>.gen\sources_1\bd\design_1\hw_handoff\design_1.hwh |


- DATEIEN GLEICH BENENNEN: PYNQ sucht die .hwh-Datei anhand des Namens der .bit-Datei. Beide müssen deshalb denselben Namen haben, nur mit anderer Endung (add_test.bit, add_test.hwh)

In Jupyter Notebook http://192.168.2.99:9090:

1. Neuen Folder add_test erstellt, add_test.bit, add_test.hwh uploadet  
2. Folgenden Code ausgefuehrt:
```
from pynq import Overlay

ol = Overlay("/home/xilinx/jupyter_notebooks/add_test/add_test.bit")

for name, info in ol.ip_dict.items():
    print(name, hex(info['phys_addr']))
    gpio_ab  = ol.axi_gpio_2   # a,b
gpio_res = ol.axi_gpio_1   # result

gpio_ab.mmio.write(0x0, 5)  
gpio_ab.mmio.write(0x8, 35)   

print(gpio_res.mmio.read(0x0))  
```
Als Ergebnis habe ich 40 bekommen.

**TODO Next:** C Code/ AXI Stream

### Reset Logic
https://stitt-hub.com/crafting-clean-reset-logic/

## Woche 3
*[13. November - 18. November]*
Ich habe Synapsenmodul geschrieben, mit Testbench getestet. LIF auf CUBA LIF (exponentieller Zerfall) erweitert. Timing Probleme.. WNS -0.049 und TNS -0.197