---
title: 'Kalkulačka reálných mezd'
layout: post
date: 2024-12-08
tags: [tool]
pin: true
math: true
published: true
lang: cs
---


  <p>Zadej svou nástupní nebo dřívější mzdu a měsíc nástupu nebo jindy v minulosti (nejpozději ale leden 2000) a zjisti, jakou by měla hodnotu v pěnězích v <span id="last_month"></span>. Dokázal zaměstnavatel ocenit tvůj profesní rozvoj a věrnost a dostáváš díky přídavkům na mzdě skutečně vyšší hodnotu, než dřív?</p>
  <label for="month">Měsíc nástupu: </label> 
  <input type="month" id="month" min="2000-01" placeholder="YYYY-MM">

  <label for="salary">Nástupní nebo dřívější plat (Kč): </label>

  <input type="currency" id="salary" placeholder="Nástupní plat" step="1">
  <button onclick="calculateInflation()">Uprav o inflaci</button>

  <h3 id="result"></h3>

  <a href="https://csu.gov.cz/mira_inflace">Zdroj dat: Český Statistický Úřad.</a> 
  <blockquote>
  Míra inflace vyjádřená přírůstkem
  průměrného ročního indexu spotřebitelských cen vyjadřuje procentní změnu průměrné cenové hladiny za 12 posledních
  měsíců proti průměru 12 předchozích měsíců.
  Tato míra inflace je vhodná při úpravách nebo posuzování průměrných veličin. Bere se v úvahu zejména při propočtech
  reálných mezd, důchodů a pod.
  </blockquote>

  <div id="tablecopy" class="table-wrapper"></div>

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
        const table = doc.getElementsByTagName('table')[0];
        document.getElementById('tablecopy').appendChild(table.cloneNode(table.cloneNode(true)));
        const cells = table.getElementsByTagName('td');

        inflationData.data = Array.from(cells).map(cell => parseFloat(cell.textContent.replace(',', '.')));

        while (inflationData.data.length > 0 && isNaN(inflationData.data[inflationData.data.length - 1])) {
          inflationData.data.pop();
        }

        const startDate = new Date(2000, 0);
        const currentDate = new Date(startDate.setMonth(startDate.getMonth() + inflationData.data.length));
        inflationData.currentMonth = months[currentDate.getMonth()] + " " + currentDate.getFullYear();
        document.getElementById('last_month').textContent = inflationData.currentMonth;

        inflationData.isLoaded = true;
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
    let index = (year - 2000) * 12 + month;
    let totalInflation = 1.0;

    while (index < inflationData.data.length) {
      monthlyRate = Math.pow(1 + inflationData.data[index] / 100, 1 / 12);
      totalInflation *= monthlyRate;
      index++;
    }
    adjustedSalary = salaryInput * totalInflation;
    const totalInflationPercent = (totalInflation - 1.0) * 100;

    document.getElementById("result").innerText =
      `To by v ${inflationData.currentMonth} mělo hodnotu: ${adjustedSalary.toFixed(0)} Kč. Nárůst cen je tedy ${totalInflationPercent.toFixed(1)}%.`;
  }

  document.addEventListener('DOMContentLoaded', () => {
    fetchInflationDataOnce();
  });

</script>

