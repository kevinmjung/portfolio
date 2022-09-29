n = 86; %filter order 
fo = [0,.15,.2,.25,.35,1]; %normalized Frequencies 
ao = [0,0,1,1,0,0]; %amplitudes
w = [1,1.7544,10]; %weights
initfilter = firpm(86, fo ,ao, w);
bits = 15; %bits for both filter and input
roundedfilter = initfilter; 
%round each element of the filter to bit length
for i = 1:length(initfilter)
    roundedfilter(i) = roundoff(initfilter(i),bits);
end
SNRarray = zeros(1,10); %storage array to run min on later
%loop to perform a sweep of different inputs 
for test = 1:10 
    %forming the input 
    inputfreq = 100000+(test)*2500;
    samplingfreq = 1000000;
    samples = 100000;
    sinput = sin(2*pi*inputfreq/samplingfreq*(1:samples));
    sinput = sinput*.5; 
    %bit limiting input
    srinput = zeros(1,length(sinput));
    for i = 1:length(sinput)
        srinput(i) = roundoff(sinput(i),15);
    end
    %convolution manual
    outputlength = length(srinput)+length(roundedfilter) - 1;
    soutput = zeros(1,outputlength);
    soutputbeta = conv(roundedfilter,sinput);
    for x = 1:length(soutput)
        for y = 1:length(roundedfilter)
            yplace = y -1 -length(roundedfilter);
            xplace = x-y+1;
            if(xplace < 1) || xplace > length(srinput)
                multicand = 0;
            else 
                multicand = srinput(xplace);
            end
            %rounding each multiplication
            roundedmulticand =  roundoff(multicand * roundedfilter(y), bits);
            soutput(x) = soutput(x) +roundedmulticand;
        end
    end
    SNRarray(test) = snr(soutput, samplingfreq);
    %make time domain graph of SNR 
    if test == 9
        snr(soutput, samplingfreq);
    end
end
%get min SNR 
minimum_SNR = min(SNRarray);
roundedfreq = fvtool(roundedfilter);
roundedfreq.Name = "finite Freq resp";
roundedfreq.CurrentAxes.Title.String = "Frequency Response with finite percesion (dB)";
roundedfreq;
roundedpz = fvtool(roundedfilter, 'Analysis', 'polezero');
roundedpz.Name = "finite pole zero";
roundedpz.CurrentAxes.Title.String = "pole-zero plot with finite percesion";
roundedpz;
roundedimp = fvtool(roundedfilter, 'Analysis', 'impulse');
roundedimp.Name = "finite impulse";
roundedimp.CurrentAxes.Title.String = "impulse response with finite percesion";
roundedimp; 
roundedgrp = fvtool(roundedfilter, 'Analysis', 'grpdelay');
roundedgrp.Name = "finite grp delay";
roundedgrp.CurrentAxes.Title.String = "group delay with finite percision";
roundedgrp; 


initfreq = fvtool(initfilter);
initfreq.Name = "non-finite freq resp";
initfreq.CurrentAxes.Title.String = "Frequency Response without finite percesion (dB)";
initfreq;
initpz = fvtool(initfilter, 'Analysis', 'polezero');
initpz.Name = "non-finite pole-zero";
initpz.CurrentAxes.Title.String = "pole-zero plot without finite percesion";
initpz;
initimp = fvtool(initfilter, 'Analysis', 'impulse');
initimp.Name = "non-finite impulse";
initimp.CurrentAxes.Title.String = "impulse response without finite percesion";
initimp;

%fvtool(initialfilter)
%zplane(roundedfilter)
%zplane

%scrap work to find how the zeros seperated 
H = dfilt.dffir(initfilter);
[rts, pdef, k] = zplane(dfilt.dffir(initfilter));
ang = angle(rts)/pi;
absang = abs(ang);
s1 = [];
sp1 = [];
s2 = [];
sebin = [];
se_c= 1;
si1 = 1;
spi1= 1;
si2 = 1;
count = 1;
for i = 1:length(absang)
    if absang(i) <= .15
        s1(si1) = rts(count);
        si1 = si1 + 1;
    elseif (absang(i) >= .2) && (absang(i) <= .25)
        sp1(spi1) = rts(count);
        spi1 = spi1+ 1; 
    elseif absang(i) >= .35
        s2(si2) = rts(count);
        si2 = si2+ 1;  
    else
        sebin(se_c) = absang(i);
        se_c = se_c+ 1; 
    end
    count = count +1; 
end 

%rounding function definition
function rounded = roundoff(n, bits)
        rounded = round(n/(2^-bits)) * 2^-bits;
end 