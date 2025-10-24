    # 🏦 KipuBank

**Autor:** Marcelo Amaya  
**Licencia:** MIT  
**Versión:** 1.0.0

---

## 📜 Descripción

**KipuBank** es un contrato inteligente desarrollado en Solidity que simula el funcionamiento de un banco descentralizado donde los usuarios pueden **depositar** y **retirar** ETH (tokens nativos de Ethereum).  
Cada usuario tiene su propia **cuenta personal**, y el sistema aplica:

- Un **límite máximo de retiro por transacción**, definido como `i_withdrawLimit`.
- Un **límite global de fondos del banco**, definido como `i_bankCap`.

El contrato también lleva un registro de:

- La cantidad total de **depósitos** y **retiros** exitosos.
- El **saldo total del banco**.
- El **saldo individual** de cada usuario.

Este contrato fue diseñado siguiendo las mejores prácticas de seguridad:

- Patrón **checks-effects-interactions**.
- Implementación de **reentrancy guard** para prevenir ataques.
- Buenas prácticas de legibilidad, comentarios NatSpec y errores personalizados.

> ⚠️ **Nota:** Este proyecto es de propósito educativo. No debe usarse en entornos de producción ni para manejo de fondos reales.

---

## ⚙️ Funcionalidades principales

### 1. Depósitos (`deposit`)

Permite al usuario enviar ETH al contrato, incrementando su saldo personal y el saldo global del banco.  
Si el nuevo total supera el límite global (`bankCap`), la operación revierte.

### 2. Retiros (`withdraw`)

Permite retirar ETH desde la bóveda personal, respetando:

- El límite de retiro por transacción.
- El saldo disponible del usuario.

### 3. Consulta de saldo (`getVaultBalance`)

Función `view` que devuelve el saldo actual de cualquier usuario.

---

## 🔒 Seguridad

- **Reentrancy Guard:** Protege las funciones sensibles de ataques de reentrada.
- **Errores personalizados:** Proporcionan diagnósticos más claros y ahorro de gas.
- **Checks-Effects-Interactions:** Garantiza ejecución segura en todas las operaciones con ETH.

---

## ⚙️ Instrucciones de despliegue

Para desplegar el contrato KipuBank en Remix utilizando Sepolia Testnet:

1. Abrí MetaMask y seleccioná la red Sepolia Test Network.

2 En Remix, en el panel Deploy & Run Transactions, elegí Injected Provider - MetaMask como Environment.

3. Cargá el contrato KipuBank.sol en Remix.

4. En el constructor, definí los parámetros:

5. \_withdrawLimit: límite máximo de retiro por transacción (en wei o ether).

6. \_bankCap: límite global del banco (en wei o ether).

7. Hacé click en Deploy y confirmá la transacción en MetaMask.

8. Una vez confirmada, copiá la dirección del contrato desplegado.

9. Podés verificarlo en Etherscan (Sepolia) usando la dirección copiada.

## 🚀 Despliegue de prueba

Una versión de prueba del contrato está desplegada en la red **Sepolia Testnet**:

👉 [Ver en Etherscan](https://sepolia.etherscan.io/address/0xbc54d5132c75af0ed8744e377618a7ddf2f4f25f)

### Parámetros de despliegue:

- **Límite máximo por retiro:** `1 ether`
- **Límite global del banco:** `100 ether`

---

## 🧠 Ejemplo de uso (Remix / Web3)

### Depósito

```solidity
KipuBank.deposit{value: 2 ether}();
```

### Retiro

```solidity
KipuBank.withdraw(0.5 ether);
```

### Consulta de saldo

```solidity
KipuBank.getVaultBalance(msg.sender);
```

---

## 📄 Licencia

Este proyecto se distribuye bajo la licencia **MIT**, de uso libre con propósitos educativos y de investigación.
