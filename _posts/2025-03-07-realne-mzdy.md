---
title: 'Kalkulačka reálných mezd'
layout: post
date: 2024-12-08
tags: [tool]
pin: true
math: true
published: true
---


  <p>Zadej svou nástupní nebo dřívější mzdu a měsíc nástupu nebo jindy v minulosti (nejpozději ale leden 2000) a zjisti, jakou by měla hodnotu v pěnězích v <span id="last_month"></span>. Dokázal zaměstnavatel ocenit tvůj profesní rozvoj a věrnost a dostáváš díky přídavkům na mzdě skutečně vyšší hodnotu, než dřív?</p>
  <label for="month">Měsíc nástupu:</label> 
  <input type="month" id="month" min="2000-01">

  <label for="salary">Nástupní nebo dřívější plat (Kč):</label>

  <input type="currency" id="salary" placeholder="Nástupní plat" step="1">
  <button onclick="calculateInflation()">Uprav o inflaci</button>

  <h3 id="result"></h3>

  <a href="https://csu.gov.cz/mira_inflace">Zdroj dat: Český Statistický Úřad.</a> Míra inflace vyjádřená přírůstkem
  průměrného ročního indexu spotřebitelských cen vyjadřuje procentní změnu průměrné cenové hladiny za 12 posledních
  měsíců proti průměru 12 předchozích měsíců.
  Tato míra inflace je vhodná při úpravách nebo posuzování průměrných veličin. Bere se v úvahu zejména při propočtech
  reálných mezd, důchodů a pod.
  <div id="tablecopy"></div>

<script>
  let inflationData = {
    data: [],
    lastDate: null,
    currentMonth: null,
    isLoaded: false,
    isLoading: false
  };
  const months = ["lednu", "únoru", "březnu", "dubnu", "květnu", "červnu", "červenci", "srpnu", "září", "říjnu", "listopadu", "prosinci"];

  async function fetchInflationDataOnce() {
    if (inflationData.isLoaded || inflationData.isLoading) {
      return inflationData;
    }

    inflationData.isLoading = true;

    try {
      const proxyUrl = 'https://corsproxy.io/?url=';
      const doc = await fetchAndParseHTML(proxyUrl + 'https://csu.gov.cz/mira_inflace');

      if (doc) {
        console.log("HTML data fetched successfully");

        const table = doc.getElementsByTagName('table')[0];
        console.log(table);

        document.getElementById('tablecopy').appendChild(table.cloneNode(table.cloneNode(true)));

        const cells = table.getElementsByTagName('td');
        console.log(cells);

        inflationData.data = Array.from(cells).map(cell => parseFloat(cell.textContent.replace(',', '.')));

        while (inflationData.data.length > 0 && isNaN(inflationData.data[inflationData.data.length - 1])) {
          inflationData.data.pop();
        }

        const startDate = new Date(2000, 0);
        const currentDate = new Date(startDate.setMonth(startDate.getMonth() + inflationData.data.length));
        inflationData.currentMonth = months[currentDate.getMonth()] + " " + currentDate.getFullYear();
        document.getElementById('last_month').textContent = inflationData.currentMonth;

        inflationData.isLoaded = true;
        console.log("Inflation data processed and stored");
      }
    } catch (error) {
      console.error("Error processing inflation data:", error);
    } finally {
      inflationData.isLoading = false;
    }

    return inflationData;
  }

  async function fetchAndParseHTML(url) {
    try {
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }

      const htmlText = await response.text();
      const parser = new DOMParser();
      const doc = parser.parseFromString(htmlText, "text/html");
      return doc;

    } catch (error) {
      console.error("Error fetching or parsing HTML:", error);
      return null;
    }
  }
  function calculateInflation() {
    if (!inflationData.isLoaded) {
      console.log("Data not yet loaded. Loading now...");
      fetchInflationDataOnce().then(() => calculateInflation(period));
      return;
    }

    const monthInput = document.getElementById("month").value;
    const errorMessage = document.getElementById("error-message");

    const salaryInput = parseFloat(document.getElementById("salary").value);
    if (!monthInput || isNaN(salaryInput) || salaryInput <= 0 || monthInput < "2000-01") {
      document.getElementById("result").innerText = "Měsíc musí být ve formátu YYYY-MM a nejdříve Leden 2000.";
      return;
    }

    const [year, month] = monthInput.split('-').map(Number);
    let adjustedSalary = salaryInput;
    let index = (year - 2000) * 12 + month;

    while (index < inflationData.data.length) {
      let monthlyRate = Math.pow(1 + inflationData.data[index] / 100, 1 / 12);
      adjustedSalary *= monthlyRate;
      index++;
    }

    document.getElementById("result").innerText =
      `To by v ${inflationData.currentMonth} odpovídalo: ${adjustedSalary.toFixed(0)} Kč`;
  }

  document.addEventListener('DOMContentLoaded', () => {
    console.log("Page loaded, fetching inflation data...");
    fetchInflationDataOnce();
  });

</script>

