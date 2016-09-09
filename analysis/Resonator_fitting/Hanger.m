function S21 = Hanger(FitParameter,x)

    Ql=FitParameter(2);
    S21min=FitParameter(1);
    baseline=FitParameter(3);
    fo=FitParameter(4);
    alpha=FitParameter(5);
    slope=FitParameter(6);
    S21=baseline*abs(( S21min+ 2*alpha*(x-fo)/fo + 1i*2*Ql*(x-fo)/fo) ./ (1 + 2*alpha*(x-fo)/fo + 1i*2*Ql*(x-fo)/fo))+slope*(x-fo);

end