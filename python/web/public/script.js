let searchTable;

function renderSearchTable(data) {
  const results = data.data || [];
  const header = document.getElementById('search-header');
  header.innerHTML = '';
  const columns = [];
  if (results.length) {
    for (const key of Object.keys(results[0])) {
      columns.push({ data: key });
      const th = document.createElement('th');
      th.textContent = key;
      header.appendChild(th);
    }
  }
  if (searchTable) {
    searchTable.destroy();
    document.querySelector('#search-table tbody').innerHTML = '';
  }
  searchTable = new DataTable('#search-table', { data: results, columns: columns });
}

document.getElementById('search-btn').addEventListener('click', () => {
  const query = document.getElementById('search-query').value;
  fetch('/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query })
  })
    .then(res => res.json())
    .then(renderSearchTable)
    .catch(err => alert('Error: ' + err));
});

function addMappingRow() {
  const rows = document.querySelectorAll('.mapping-row');
  if (rows.length >= 5) return;
  const div = document.createElement('div');
  div.className = 'mapping-row';
  div.innerHTML = '<input class="idType" placeholder="idType"> ' +
                  '<input class="idValue" placeholder="idValue"> ' +
                  '<input class="exchCode" placeholder="exchCode">';
  document.getElementById('mapping-rows').appendChild(div);
}

document.getElementById('add-row').addEventListener('click', addMappingRow);
addMappingRow();

document.getElementById('map-btn').addEventListener('click', () => {
  const rows = document.querySelectorAll('.mapping-row');
  const requests = [];
  rows.forEach(row => {
    const idType = row.querySelector('.idType').value;
    const idValue = row.querySelector('.idValue').value;
    const exchCode = row.querySelector('.exchCode').value;
    if (idType && idValue) {
      const obj = { idType, idValue };
      if (exchCode) obj.exchCode = exchCode;
      requests.push(obj);
    }
  });
  fetch('/mapping', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ requests })
  })
    .then(res => res.json())
    .then(data => {
      const container = document.getElementById('mapping-results');
      container.innerHTML = '';
      data.forEach((res, idx) => {
        const div = document.createElement('div');
        div.className = 'mapping-result';
        div.innerHTML = '<strong>Request ' + (idx + 1) + '</strong>\n' +
                        JSON.stringify(res, null, 2);
        container.appendChild(div);
      });
    })
    .catch(err => alert('Error: ' + err));
});
