"""Conferência independente (opcional): recalcula em Python os números principais do R.

Não usa nenhum código R. Serve para checar se o recorte da coorte, o prazo de 60 dias e
a sobrevida de Kaplan-Meier do R batem. Rode na pasta do projeto:

    python3 conferencia/conferencia_python.py

Lê os .xlsx em dados/ e grava conferencia/valores_esperados.csv.
Depois, no R:  source("conferencia/comparar.R")
Os critérios abaixo precisam ser iguais aos de funcoes_padrao.R.
"""
import pandas as pd, numpy as np

PASTA = 'dados/'
ARQ_MESO = 'dados/municipios_mg_mesorregioes_codigo_ibge_2025.csv'
SAIDA = 'conferencia/valores_esperados.csv'
APENAS_SUS = True          # = apenas_sus em funcoes_padrao.R
APENAS_ANALITICOS = False  # = apenas_analiticos em funcoes_padrao.R
CORTE = pd.Timestamp('2024-12-31')
INI, FIM = pd.Timestamp('2019-01-01'), pd.Timestamp('2024-12-31')
ARQUIVOS = {'vulva': 'rhc_imp_vulva_2019_2024.xlsx', 'colo_utero': 'rhc_imp_colo_uterino_2019_2024.xlsx',
            'endometrio': 'rhc_imp_endometrio_2019_2024.xlsx', 'ovario': 'rhc_imp_ovario_2019_2024.xlsx'}

meso = pd.read_csv(ARQ_MESO, dtype=str)


def km(t, e):
    df = pd.DataFrame({'t': t, 'e': e}).sort_values('t')
    s, out = 1.0, [(0.0, 1.0)]
    for u in sorted(df.t[df.e == 1].unique()):
        n = (df.t >= u).sum()
        d = ((df.t == u) & (df.e == 1)).sum()
        s *= 1 - d / n
        out.append((u, s))
    return pd.DataFrame(out, columns=['t', 'S'])


def em(c, x, maxt):
    return np.nan if maxt < x else c.S[c.t <= x].iloc[-1]


linhas = []
for nome, arq in ARQUIVOS.items():
    d = pd.read_excel(PASTA + arq, dtype=str, keep_default_na=False)
    for c in d.columns:
        d[c] = d[c].str.strip()
    d['dx'] = pd.to_datetime(d.DTDIAGNO, format='%d/%m/%Y', errors='coerce')
    d['tr'] = pd.to_datetime(d.DTINITRT.where(d.DTINITRT != '88/88/8888'), format='%d/%m/%Y', errors='coerce')
    d['ob'] = pd.to_datetime(d.DTOBITO, format='%d/%m/%Y', errors='coerce')
    n0 = len(d)
    r = d[d.DIAGANT.isin(['1', '2'])]; n1 = len(r)
    r = r[r.tr.notna()]; n2 = len(r)
    r = r[r.UF == 'MG']; n3 = len(r)
    r = r[(r.dx >= INI) & (r.dx <= FIM)]; n4 = len(r)
    r = r[(r.tr >= INI) & (r.tr <= FIM)]; n5 = len(r)
    if APENAS_SUS:
        r = r[r.CUSTRATAMTUMOR == '1']
    n6 = len(r)
    if APENAS_ANALITICOS:
        r = r[r.ANALITIC == '1']
    dias = (r.tr - r.dx).dt.days
    ev = (r.ob.notna() & (r.ob <= CORTE)).astype(int)
    fim = r.ob.where(ev == 1, CORTE)
    tmp = (fim - r.dx).dt.days / 30.4375
    ok = tmp >= 0
    k = km(tmp[ok], ev[ok])
    med = k.t[k.S <= 0.5].min() if (k.S <= 0.5).any() else np.nan
    m = r.merge(meso, left_on='PROCEDEN', right_on='codigo_ibge', how='left')
    linhas.append(dict(
        cancer=nome, n_arquivo=n0, n_diagant12=n1, n_trat_hosp=n2, n_mg=n3, n_dx_janela=n4, n_trat_janela=n5,
        n_sus=n6, n_final=len(r), idade_mediana=r.IDADE.astype(int).median(), dias_med=dias.median(),
        dias_neg=int((dias < 0).sum()), n_ate60=int((dias <= 60).sum()), pct_ate60=round((dias <= 60).mean() * 100, 1),
        obitos_ate_corte=int(ev.sum()), obito_cancer=int((r.OBITOPORCANCER == '1').sum()),
        obito_outra=int((r.OBITOPORCANCER == '2').sum()),
        km_mediana_meses=round(med, 1) if med == med else np.nan,
        s12=round(em(k, 12, tmp.max()), 3), s36=round(em(k, 36, tmp.max()), 3), s60=round(em(k, 60, tmp.max()), 3),
        sem_meso=int(m.mesorregiao.isna().sum()), maxfu_meses=round(tmp.max(), 1)))

res = pd.DataFrame(linhas)
pd.set_option('display.width', 250)
print(res.T.to_string())
res.to_csv(SAIDA, index=False)
