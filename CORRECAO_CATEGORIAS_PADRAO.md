# Correção do Sistema de Categorias Padrão

## 🐛 Problema Identificado

O erro `UNIQUE constraint failed: categories.id` estava ocorrendo porque:

1. **IDs duplicados**: As categorias padrão usavam IDs fixos (`alimentacao`, `transporte`, etc.) que conflitavam entre usuários
2. **Execução simultânea**: Múltiplas tentativas de inicialização aconteciam ao mesmo tempo
3. **Falta de verificação robusta**: O sistema não verificava adequadamente se as categorias já existiam

## ✅ Soluções Implementadas

### 1. **IDs Únicos por Usuário**
- **Antes**: `alimentacao`
- **Depois**: `alimentacao_Y7naCF9kKYc5s9KmDOtWR8nbSJG3`
- Cada usuário tem suas próprias categorias com IDs únicos

### 2. **INSERT OR IGNORE**
```sql
INSERT OR IGNORE INTO categories 
(id, userId, name, icon, color, keywords, isDefault) 
VALUES (?, ?, ?, ?, ?, ?, ?)
```
- Evita erros de constraint se categoria já existir
- Operação segura e idempotente

### 3. **Lock de Concorrência**
```dart
static bool _isInitializingCategories = false;
```
- Previne execução simultânea do método de inicialização
- Evita condições de corrida

### 4. **Verificação Robusta**
- Verifica categorias existentes antes de criar
- Logs detalhados para debugging
- Tratamento de erros em cada etapa

### 5. **Método de Recuperação**
```dart
Future<void> forceRecreateDefaultCategories()
```
- Remove categorias padrão antigas
- Recria com IDs únicos
- Usado como fallback em caso de problemas

## 🔧 Arquivos Modificados

### 1. `expense_local_datasource.dart`
- ✅ Adicionado lock de concorrência
- ✅ IDs únicos por usuário
- ✅ INSERT OR IGNORE
- ✅ Logs detalhados
- ✅ Método de recriação forçada

### 2. `expense_hybrid_repository.dart`
- ✅ Logs melhorados
- ✅ Tratamento de erros robusto
- ✅ Método público para forçar recriação
- ✅ Fallback em caso de erro

### 3. `expense_controller.dart`
- ✅ Retry automático com recriação
- ✅ Integração com método de recuperação
- ✅ Logs para debugging

## 🎯 Resultado Esperado

Agora as categorias padrão devem:

1. **Aparecer sempre** que o usuário for registrar uma despesa
2. **Não gerar erros** de constraint
3. **Ser únicas por usuário** (não conflitar entre usuários)
4. **Se recuperar automaticamente** em caso de problemas
5. **Funcionar offline** e sincronizar quando possível

## 🧪 Como Testar

1. **Fazer hot restart** do app
2. **Ir para "Nova Despesa"**
3. **Verificar se as 12 categorias aparecem**
4. **Testar com diferentes usuários**
5. **Verificar logs no console**

## 📊 Logs Esperados

```
🔍 Verificando categorias existentes para usuário: Y7naCF9kKYc5s9KmDOtWR8nbSJG3
📊 Categorias existentes encontradas: 0
🏷️ Inicializando categorias padrão...
✅ Categoria "Alimentação" criada
✅ Categoria "Transporte" criada
...
✅ Categorias padrão inicializadas para usuário: Y7naCF9kKYc5s9KmDOtWR8nbSJG3
✅ 12 categorias carregadas
```

## 🔄 Próximos Passos

Se ainda houver problemas:

1. **Verificar logs** no console
2. **Limpar dados do app** (se necessário)
3. **Testar com usuário novo**
4. **Verificar sincronização com Firestore**

As correções implementadas devem resolver completamente o problema de categorias padrão não aparecendo na tela de registro de despesas.
