## P3P Final report - plan

<!--

Things I need to write about (10000 words max):

- Background

- Personal Contributions and benefits
	- How I benefitted from this project
	- Skills I used / improved over the course of the project
	- What my contributions were (What I did that hasn't been done before)

- Overall system design / layout
	- SystemVerilog block diagrams etc
	- Algorithms/methods implemented/used
	- Linkage between L'Imperatrice and La Papessa
	- Overview of hardware environment

- Detailed description of each component
	- L'Imperatrice
		- Data extraction (audio processing??)
		- Comms
	- La Papessa
		- SRAM
		- GDP pipe
		- Normaliser
		- UART (note: reference fpga4fun - "...standard pattern, described on []")

- Testing and Evaluation
	- Lisp software written to parse HTK files and test the SV code
	- Test vectors used
	- Benchmarks against established software (e.g. HTK)
	- Hardware vs software speed benchmarks
	- Evaluate results with respect to project goals / plan 

- Reflections and Conclusions
	- Comparison of actual work with planned work (Gantt charts etc)
	- How was work cut down from the original plan?
	- Personal Reflections
		+ What would I do differently a second time?
		+ What have I learnt?
		+ Were my goals sensible, etc?
	- Possible future work / projects based on this work

-->

### Major sections:

- Intro + Goals of project

- Background
	+ Literature review etc
	+ Detail of the ASR problem (?), previous approaches to solving it
	+ Reasons for using FPGAs
	+ Micro Arcana
	+ etc. Take content from interim
	
- My approach / solution to the problem (overview)
	+ Full system overview
	+ Skills I had / needed to acquire
	+ Analysis of solution - my contribution, usefulness, extendability, etc

- Detailed description of each component
	+ L'Imperatrice
		* Data extraction (audio processing??)
		* Comms
	+ La Papessa
		* SRAM
		* GDP pipe
		* Normaliser
		* UART
	+ 

- Testing / Results of individual components and full system
	+ L'Imperatrice
	+ La Papessa
	+ Lisp software written to parse HTK files and test the SV code
	+ Test vectors used
	+ Benchmarks against established software (e.g. HTK)
	+ Hardware vs software speed benchmarks

- Project management
	+ Comparison of actual work with planned work (Gantt charts etc)
	+ How was work cut down from the original plan?
	+ Evaluate results with respect to project goals / plan 

- Reflections, Conclusions
	+ Personal Reflections
		* What would I do differently a second time?
		* What have I learnt?
		* Were my original goals sensible, etc?
	+ Possible future work / projects based on this work

- Appendices
	+ Original project brief
	+ Instructions for using Synplify etc, setting up LTIB
	+ Detailed info of the ASR problem (?)