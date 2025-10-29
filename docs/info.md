<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

A way of estimating resistance for external sensors without a mixed signal ADC. Excites an external RC cicuit with a step, and measures the rise time to calculate a rough resistance.

## How to test

Top level module contains 2 external outputs and one input. The outputs are the exciting step, and resistance value, and the input is the received rise step from RC circuit.

## External hardware

External hardware is just the RC circuit you are measuring.
