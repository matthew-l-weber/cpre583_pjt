cpre583_pjt
===========

Group 2 Project Submission: SHA-1 Implementation on a SoC FPGA

Nathan Miller, Matthew L Weber, Jay Guild

ComS/CprE 583: Reconﬁgurable Computing ,

Iowa State University 2013

Abstract—This project seeks to characterize the acceleration of a Linux Kernel cryptography algorithm using programmable logic. It targets a speciﬁc algorithm and uses a combination of open source user space applications, new kernel drivers, and custom logic to perform the analysis.

I. INTRODUCTION

Acceleration of a cryptographic algorithms on an embedded device remains an outstanding challenge. New System on Chip (SoC) FPGA technologies provide more options to ofﬂoad or accelerate the cryptographic computations, however, integrating these technologies into existing designs can be challenging. Similarly, migrating designs between different SoC FPGA platforms can also require a signiﬁcant investment of time and resources. Even though the system functionality and underlying algorithms remain unchanged, the design teams are forced to re-invent their designs for each new platform. We believe this effort hampers the wider adoption of SoC FPGA technologies within the industry.  This project seeks to characterize the effort of porting an cryptographic algorithm to a SoC FPGA prototype containing a fabric based accelerator and provide empirical performance data showing the beneﬁts of doing so. The prototype will be running the Linux/BSD Cryptodev framework to transparently provide user-space programs with access to cryptographic functions. This prototype leverages similar concepts implemented on Texas Instruments SoC processors to tie their hardware accelerators into the Linux Kernel.

II. RELATED WORK

Cryptography is the process of encrypting information using an algorithm and either a public key (asymmetric encryption) or a private key (symmetric encryption) that makes the information unreadable unless the data is passed through a decryption algorithm that utilizes a private key that only the receiver holds[16]. Several keys and algorithms have been developed under the IEEE standard for public key cryptography [17] and studied in several different environments for effectiveness and speed. It has been found that over networks with cryptography implemented that the limiting factor for most systems in speed is the network itself so using software to handle cryptography has not helped to speed up processing time much [18]. With speeds always increasing on communication buses this will change soon though. The largerst bonuses in the recent past have been seen when adding a co-processor or FPGA to handle cryptography. By adding a co-processor or FPGA effectiveness is increased because computations can be done in parallel and logic can be handled in fewer steps[19]. Computations are also hard wired and coded into circuits and that creates a security that software in a single dedicated processor can’t match because that software can be manipulated by outside code[18]. A SoC FPGA that can process cryptography very fast using parallelization in a low cost implementation can resolve any issues that using a single processor software solution creates.

III. WHY IS THIS INTERESTING

In the last two years various industry leading programmable logic companies have invested millions in creating consolidated system on a chip (SoC) products. Fusing mainstream processor technology (primarily ARM-based cores) with the latest fabric technology, the result has been the creation of highly conﬁgurable embedded devices. This is very relevant to bleeding edge signal processing developments (cryptography/video/audio/RF), where a general purpose processor is commonly paired with a programmable device for initial prototyping and in some cases the ﬁnal product. The latest SoC FPGA technology allows a consolidation that has largely eliminated many interface design activities and has encouraged more of a accelerator/coprocessor style of development. The key to this ﬂexibility is having the SoC execute code that may tap into a fabric logic to parallelize an operation or having SoC completely hand off data to the fabric (leaving the SoC free to perform other operations).
Parallel operations in an FPGA using incorruptible LUTs and unidentifiable return data also has the positive effect of added security for sensitive systems such as the one being implemented here.  When a possible intrusion to the system would reach the encoding of the FPGA there is a blockage in communication that would not allow the intruder to see what operations are being done to the incoming data to the microprocessor from the FPGA.  To be able to garner data an intruder would need to be able to monitor data prior to processing and that is only done on the outgoing side from the originator.  There is also no way for an intruder to manipulate the FPGA to try and detect the encoding due to it’s nature of having permanent operations that are a physical architecture inside the chip.  This makes this type of implementation very useful in security sensitive communication systems.

Project overview

Our original project proposal suggested using a framework called Open Crypto Framework (OCF).  It turned out OCF was deprecated and not functional with newer Linux kernels.  Instead the Cryptodev development now provides a comparable capability along with a set of test applications used for validation and benchmarking.  This works out to fulfill the Crypto API and TestApp portions of the design.  The SHA1 entity is based on an Opencore core.
As originally proposed, the architecture [Figure 1] consists of a software kernel driver API, user space application, as well as a programmable logic (PL) entity.  Using these components, an initial implementation yielded a functional implementation of the SHA1 algorithm using the PL to compute the hash results.
