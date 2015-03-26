function pauliMap = unitary2pauli(unitaryIn)

pauliMap = choi2pauliMap(unitary2choi(unitaryIn));