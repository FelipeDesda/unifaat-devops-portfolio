const fs = require('fs');
const path = require('path');

// ============================================
// Script de AI Review para TechNova
// ============================================
// Este script analisa o diff do PR e identifica problemas.
// Em produção, a seção "analyzeWithAI" chamaria Bedrock/OpenAI.
// Para o lab, usamos análise baseada em regras (pattern matching).

const SEVERITY = {
  CRITICAL: '🔴 CRITICAL',
  WARNING: '🟡 WARNING',
  INFO: '🔵 INFO'
};

// Padrões de problemas a detectar
const SECURITY_PATTERNS = [
  {
    pattern: /(password|secret|key|token)\s*[:=]\s*['"][^'"]+['"]/gi,
    message: 'Possível secret/credencial hardcoded detectada',
    severity: SEVERITY.CRITICAL
  },
  {
    pattern: /eval\s*\(/g,
    message: 'Uso de eval() - risco de code injection',
    severity: SEVERITY.CRITICAL
  },
  {
    pattern: /\bexec\s*\(\s*['"`].*\$\{/g,
    message: 'Possível command injection via template literal',
    severity: SEVERITY.CRITICAL
  },
  {
    pattern: /query\s*\(\s*['"`].*\+/g,
    message: 'Possível SQL injection - use queries parametrizadas',
    severity: SEVERITY.CRITICAL
  },
  {
    pattern: /console\.(log|debug|info)\(/g,
    message: 'Console.log em código de produção (remover ou usar logger)',
    severity: SEVERITY.WARNING
  },
  {
    pattern: /TODO|FIXME|HACK|XXX/g,
    message: 'Comentário TODO/FIXME encontrado - resolver antes de merge',
    severity: SEVERITY.INFO
  },
  {
    pattern: /catch\s*\(\s*\w*\s*\)\s*\{\s*\}/g,
    message: 'Catch vazio - erros silenciados podem esconder bugs',
    severity: SEVERITY.WARNING
  },
  {
    pattern: /0\.0\.0\.0|INADDR_ANY/g,
    message: 'Binding em 0.0.0.0 - verificar se intencional em produção',
    severity: SEVERITY.WARNING
  }
];

function analyzeDiff(diffContent) {
  const findings = [];
  const lines = diffContent.split('\n');
  let currentFile = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Detectar arquivo atual
    if (line.startsWith('+++ b/')) {
      currentFile = line.replace('+++ b/', '');
      continue;
    }

    // Analisar apenas linhas adicionadas
    if (line.startsWith('+') && !line.startsWith('+++')) {
      const addedCode = line.substring(1);

      for (const rule of SECURITY_PATTERNS) {
        if (rule.pattern.test(addedCode)) {
          findings.push({
            file: currentFile,
            line: i,
            code: addedCode.trim().substring(0, 80),
            message: rule.message,
            severity: rule.severity
          });
          // Reset regex lastIndex
          rule.pattern.lastIndex = 0;
        }
      }
    }
  }

  return findings;
}

function generateReport(findings) {
  if (findings.length === 0) {
    return `## 🤖 AI Code Review - TechNova

✅ **Nenhum problema encontrado!**

O código alterado neste PR passou pela análise automatizada sem achados.
Lembre-se: este review automático complementa, mas não substitui, o review humano.

---
*Review automatizado por AI Pipeline - TechNova DevOps*`;
  }

  const criticals = findings.filter(f => f.severity === SEVERITY.CRITICAL);
  const warnings = findings.filter(f => f.severity === SEVERITY.WARNING);
  const infos = findings.filter(f => f.severity === SEVERITY.INFO);

  let report = `## 🤖 AI Code Review - TechNova\n\n`;
  report += `**Resumo:** ${findings.length} achado(s) encontrado(s)\n`;
  report += `- ${SEVERITY.CRITICAL}: ${criticals.length}\n`;
  report += `- ${SEVERITY.WARNING}: ${warnings.length}\n`;
  report += `- ${SEVERITY.INFO}: ${infos.length}\n\n`;

  if (criticals.length > 0) {
    report += `> ⛔ **Este PR tem achados CRITICAL que devem ser corrigidos antes do merge.**\n\n`;
  }

  report += `### Achados Detalhados\n\n`;
  report += `| Severidade | Arquivo | Problema | Código |\n`;
  report += `|:----------:|---------|----------|--------|\n`;

  for (const finding of findings) {
    const shortFile = finding.file.length > 30
      ? '...' + finding.file.slice(-27)
      : finding.file;
    const shortCode = finding.code.length > 40
      ? finding.code.substring(0, 37) + '...'
      : finding.code;
    report += `| ${finding.severity} | \`${shortFile}\` | ${finding.message} | \`${shortCode}\` |\n`;
  }

  report += `\n---\n`;
  report += `*Review automatizado por AI Pipeline - TechNova DevOps*\n`;
  report += `*⚠️ Falsos positivos são possíveis. Avalie cada achado criticamente.*`;

  return report;
}

// ============================================
// Execução Principal
// ============================================
const diffFile = process.env.DIFF_FILE || '/tmp/pr-diff.txt';

try {
  const diffContent = fs.readFileSync(diffFile, 'utf8');
  const findings = analyzeDiff(diffContent);
  const report = generateReport(findings);

  // Salvar resultado para o próximo step
  fs.writeFileSync('/tmp/ai-review-result.md', report);

  console.log(`\nAnálise completa: ${findings.length} achado(s)`);
  console.log(report);

  // Se há achados CRITICAL, sinalizar (mas não falhar ainda - Parte 5 implementa isso)
  const hasCritical = findings.some(f => f.severity === SEVERITY.CRITICAL);
  if (hasCritical) {
    console.log('\n⚠️ Achados CRITICAL encontrados!');
    // process.exit(1); // Descomente na Parte 5 para bloquear PR
  }
} catch (error) {
  console.error('Erro na análise:', error.message);
  const errorReport = `## 🤖 AI Code Review - TechNova\n\n⚠️ Erro durante a análise: ${error.message}`;
  fs.writeFileSync('/tmp/ai-review-result.md', errorReport);
}

  // Bloquear PR se há achados CRITICAL
  const hasCritical = findings.some(f => f.severity === SEVERITY.CRITICAL);
  if (hasCritical) {
    console.log('\n⛔ PR BLOQUEADO: achados CRITICAL encontrados.');
    console.log('Corrija os problemas e faça push novamente.');
    process.exit(1);  // ← DESCOMENTE ESTA LINHA
  }