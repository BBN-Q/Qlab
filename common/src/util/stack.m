% a function that holds a stack as a local variable
% and returns handles to funtions that manipulates
% the stack
%
% (C) 2004 Sturla Molden
% modified 10/8/2010 by Blake Johnson
%

function f = stack

   s = [];
   f.push = @push;
   f.pop = @pop;
   f.isempty = @isempty;
   
   function push(data)
      tmp = stack_node;
      tmp.setData(data);
      tmp.setNext(s);
      s = tmp;
   end
   
   function y = pop
      if isempty
         y = [];
      else
         y = s.getData();
         s = s.getNext();
      end
   end
   
	function y = isempty
		y = ~isstruct(s);
	end

end

% a subfunction that holds a stack node in its
% local variables and returns functions for
% manipulating the stack node

function f = stack_node

   d = []; next = [];
   f.getData = @getData;
   f.setData = @setData;
   f.getNext = @getNext;
   f.setNext = @setNext;

   function y = getData
      y = d;
   end

   function setData(data)
      d = data;
   end

   function y = getNext
      y = next;
   end

   function setNext(x)
      next = x;
   end

end