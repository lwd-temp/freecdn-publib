if [[ "$1" == "init" ]]; then
  echo "init mode"
  SITES=(ajax.cdnjs.com)
  SQL_I=scan-import-1st.sql
  SQL_O=scan-export-1st.sql
else
  SITES=$(<sites.txt)
  SQL_I=scan-import-3rd.sql
  SQL_O=scan-export-3rd.sql
fi

export bit=0
export output=""

mkdir -p var/input var/output

for t in {1..10}; do
  echo "turn: $t"
  bit=1
  for site in ${SITES[@]}; do
    echo "site: $site ($bit)"

    input=var/input/$site
    output=var/output/$site

    if [ -s $output ]; then
      echo "found last result"
    else
      echo "export records ..."
      sql=$(envsubst < $SQL_O)
      mysql --skip-column-names <<< "$sql" > $input
      wc -l $input

      echo "scan ..."
      node scan.js $site $input $output
      wc -l $output
    fi

    echo "import records ..."
    sql=$(envsubst < $SQL_I)
    mysql --local-infile=1 <<< "$sql"

    rm -f $input $output
    bit=$(($bit * 2))
  done
done