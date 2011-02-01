%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Sweep.m
 %
 % Author/Date : Blake Johnson / October 15, 2010
 %
 % Description : This is an abstract base sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Sweep < handle
	properties
		name = 'Sweep'
		plotRange
		points
		Instr
	end
	
	methods (Abstract)
		step(obj, index)
	end
end