"""Execute lab scripts in PostgreSQL using psql. No Python third-party dependencies."""
from pathlib import Path
import subprocess, os, json, csv, io
ROOT=Path(__file__).resolve().parent
def psql(sql=None, file=None, variables=None, csv_output=False):
    exe=os.environ.get('PSQL','psql')
    cmd=[exe,'-X','-w','-v','ON_ERROR_STOP=1']
    for k,v in (variables or {}).items(): cmd += ['-v',f'{k}={v}']
    if csv_output: cmd += ['--csv','-t']
    cmd += ['-f',str(file)] if file else ['-c',sql]
    p=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8')
    if p.returncode: raise RuntimeError(p.stderr)
    return p.stdout
def script(name,when=None):
    return psql(file=ROOT/'sql'/name,variables={'load_dts':when} if when else None)
def rows(query):
    return list(csv.reader(io.StringIO(psql(sql=query,csv_output=True))))
def counts():
    return rows("select 'h_order',count(*) from lab08_dv.h_order union all select 's_order',count(*) from lab08_dv.s_order union all select 's_customer',count(*) from lab08_dv.s_customer union all select 's_order_item',count(*) from lab08_dv.s_order_item order by 1")
def run():
    # Use a fresh empty database. These scripts intentionally do not drop anything.
    version=psql(sql='select version();').strip()
    for n in ['01_schema_3nf.sql','02_schema_datavault.sql','03_seed.sql']: script(n)
    script('04_load_datavault.sql','2026-11-20 20:00:00+03')
    initial=counts()
    script('04_load_datavault.sql','2026-11-20 20:00:00+03')
    assert counts()==initial, 'same batch must be idempotent'
    script('04_load_datavault.sql','2026-11-21 08:00:00+03')
    assert counts()==initial, 'unchanged snapshot must not create satellite versions'
    script('05_change_snapshot.sql')
    script('04_load_datavault.sql','2026-11-21 20:00:00+03')
    script('06_complete_order.sql')
    script('04_load_datavault.sql','2026-11-22 12:00:00+03')
    script('07_views.sql')
    checks=script('08_checks.sql')
    before=counts()
    script('04_load_datavault.sql','2026-11-22 12:00:00+03')
    assert counts()==before, 'final batch replay must be idempotent'
    # Validate actual PostgreSQL FK and check enforcement without persisting bad data.
    failed=[]
    for label,stmt in [
        ('foreign key',"insert into lab08_3nf.service_order values (999,'BAD999',999,now(),now(),1)"),
        ('positive quantity',"update lab08_3nf.order_item set quantity=0 where order_id=1 and line_no=1"),
        ('unique business key',"insert into lab08_3nf.customer values (999,'C001','Test','0')")]:
        try: psql(sql='begin; '+stmt+'; rollback;')
        except RuntimeError: failed.append(label)
        else: raise AssertionError('constraint did not reject '+label)
    return dict(version=version,initial_counts=initial,final_counts=counts(),checks=checks,
        rejected_invalid_data=failed,
        history=rows("select h.order_no,s.load_dts,s.status_code from lab08_dv.h_order h join lab08_dv.s_order s using(order_hk) where order_no='O001' order by s.load_dts"),
        customer_history=rows("select h.customer_code,s.load_dts,s.phone from lab08_dv.h_customer h join lab08_dv.s_customer s using(customer_hk) where customer_code='C001' order by s.load_dts"),
        orders=rows('select * from lab08_dv.v_order_summary order by order_no'),
        totals=rows('select sum(order_amount),sum(paid_amount),sum(debt) from lab08_dv.v_order_summary'))
if __name__=='__main__':
    result=run()
    (ROOT/'results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
