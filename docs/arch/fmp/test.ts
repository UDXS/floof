with (Floof.TestAssembler) {
    myPool = literals([
        q32(5.25),
        q32(12.625)
    ])
    entrypoint();
    ena().expect(ExecMask, e => e.eq("0xFFFFFFFF"))
    relIP(G0, myPool[0].relative());
    relIP(G1, myPool[1].relative());
    ld(G3, G0).expect(G3, r => r.eq(myPool[0].value));
    ld(G4, G1).expect(G4, r => r.eq(myPool[1].value));

    PModel.waitUntil(() => Core.inFlight() == 2, timeoutAt * 8 * cycles);
    add(G2, G0, G1).expect(G2, r => r.eq(q32(17.875)))
    
    sig(signal.Host, 0, isBlocking * true);
    barrier();
    PModel.waitUntil(() => Core.inFlight() == 0, timeoutAt * 4 * cycles);
    assertFinish();
    assertCoverage(FullCoverage);

}

