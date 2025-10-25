    # 🏦 KipuBank

**Autor:** Marcelo Amaya  
**Licencia:** MIT  
**Versión:** 1.0.0

---

## 📜 Descripción

**KipuBank** es un contrato inteligente desarrollado en **Solidity** que simula el funcionamiento de un **banco descentralizado**, donde los usuarios pueden **depositar** y **retirar** ETH de sus cuentas personales.

Esta versión mejora la funcionalidad del contrato original incorporando:

- Un **oráculo Chainlink** para consultar el precio actual de ETH/USD.
- **Historial de transacciones** por usuario (depósitos y retiros).
- **Conversión de unidades** entre wei ↔ ether y entre ETH ↔ USD.
- **Control de propietario**, con funciones exclusivas de administración.
- Mecanismo de **seguridad contra reentrancia**.

Cada usuario tiene su **bóveda personal**, y el contrato mantiene:

- Límite máximo de retiro por transacción (`i_withdrawLimit`).
- Límite global de fondos del banco (`i_bankCap`).
- Contadores globales de depósitos y retiros.
- Registro detallado de todas las operaciones.

> ⚠️ **Nota:** Este proyecto es de propósito educativo. No debe usarse en entornos de producción ni para manejo de fondos reales.

---

## ⚙️ Funcionalidades principales

### 1. Depósitos (`deposit`)

Permite enviar ETH al contrato para aumentar el saldo personal del usuario.  
Si el nuevo total supera el límite global (`bankCap`), la operación revierte.

- Incrementa el contador global de depósitos.
- Guarda la transacción en el historial personal (`s_userTxHistory`).
- Emite el evento `DepositPerformed`.

### 2. Retiros (`withdraw`)

Permite retirar ETH desde la bóveda personal, respetando:

- El límite máximo de retiro (`i_withdrawLimit`).
- El saldo disponible del usuario.

- Disminuye el saldo global y personal.
- Registra la transacción en el historial.
- Emite el evento `WithdrawalPerformed`.
- Protegido por `nonReentrant`.

### 3. Consulta de saldo (`getVaultBalance`)

Devuelve el saldo actual de un usuario específico.

### 4. Valor de depósito en USD (`getDepositValueInUSD`)

Convierte un monto de ETH a su equivalente en USD usando el **oráculo Chainlink** configurado.

### 5. Normalización de decimales (`normalizeDecimals`)

Convierte montos entre diferentes precisiones decimales, útil para interoperabilidad con tokens o feeds de precios.

### 6. Conversión de unidades

- `convertToEth(uint256 amountWei)` → Convierte wei → ether
- `convertFromEth(uint256 amountEth)` → Convierte ether → wei

### 7. Funciones administrativas

- `changeOwner(address newOwner)` → Cambia el dueño del contrato.
- `updateOracle(address newOracle)` → Actualiza la dirección del oráculo Chainlink.

---

## 🔒 Seguridad

- **Reentrancy Guard:** Protege las funciones sensibles de ataques de reentrada.
- **Errores personalizados:** Proporcionan diagnósticos más claros y ahorro de gas.
- **Checks-Effects-Interactions:** Garantiza ejecución segura en todas las operaciones con ETH.
- **Acceso restringido:** funciones administrativas protegidas con `onlyOwner`.Para desplegar **KipuBank** en **Remix** utilizando **Sepolia Testnet**:

1. Abrí **MetaMask** y seleccioná la red **Sepolia Test Network**.
2. En Remix, seleccioná **Injected Provider - MetaMask** como _Environment_.
3. Cargá el archivo `KipuBank.sol` desde la carpeta `src/`.
4. En el constructor, completá los parámetros:
   - `_withdrawLimit`: límite máximo de retiro por transacción (wei o ether).
   - `_bankCap`: límite global de depósitos del banco.
   - `_oracleAddress`: dirección del oráculo Chainlink ETH/USD (Sepolia).
5. Hacé clic en **Deploy** y confirmá en MetaMask.
6. Una vez confirmada, copiá la dirección del contrato desplegado.
7. Verificalo en **Etherscan (Sepolia)** usando esa dirección.

## 🚀 Despliegue de prueba

Una versión de prueba del contrato está desplegada en la red **Sepolia Testnet**:

👉 [Ver en Etherscan](https://sepolia.etherscan.io/address/0x3e2C6428e6e52ae25c62Ad266c8874AC9BC7441d)

### Parámetros de despliegue:

- **Límite máximo por retiro:** `1 ether`
- **Límite global del banco:** `100 ether`
- **Oráculo Chainlink (ETH/USD):** `0x694AA1769357215DE4FAC081bf1f309aDC325306`

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

### Valor estimado en USD

```solidity
KipuBank.getDepositValueInUSD(1 ether);
```

---

## 📄 Licencia

Este proyecto se distribuye bajo la licencia **MIT**, de uso libre con propósitos educativos y de investigación.
