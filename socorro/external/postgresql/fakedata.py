#!/usr/bin/python

class BaseTable(object):
    def rows(self):
        for row in self._rows:
            yield row

    def generate_inserts(self):
        for row in self.rows():
            yield 'INSERT INTO %s (%s) VALUES (%s)' % (self.table,
              ', '.join(self.columns), ', '.join(row))

class CrontabberState(BaseTable):
    table = 'crontabber_state'
    columns = ['state', 'last_updated']
    _rows = [["'{}'", "2012-05-16 00:00:00"]]

def main():
    tables = [CrontabberState]
    for t in tables:
        t = t()
        for insert in t.generate_inserts():
            print insert

if __name__ == '__main__':
    main()

