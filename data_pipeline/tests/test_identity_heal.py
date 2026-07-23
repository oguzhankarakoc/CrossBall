from pipeline.identity_heal import names_are_legal_variants


def test_coutinho_legal_variant():
    assert names_are_legal_variants('Philippe Coutinho', 'Philippe Coutinho Correia')


def test_ronaldo_legal_variant():
    assert names_are_legal_variants(
        'Cristiano Ronaldo',
        'Cristiano Ronaldo dos Santos Aveiro',
    )


def test_adama_token_subset_needs_career_gate():
    # Name-only heuristic may match; find_merge_candidates still requires club overlap.
    assert names_are_legal_variants('Adama Traoré', 'Adama Traoré Diarra')


def test_perez_not_same_person():
    assert not names_are_legal_variants('Ayoze Pérez', 'Alberto Moreno Pérez')
    assert not names_are_legal_variants('Adrià Carmona Pérez', 'Aleix Febas Pérez')
