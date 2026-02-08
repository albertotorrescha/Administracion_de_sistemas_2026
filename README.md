# Administración de Sistemas (2026)
**Facultad de Ingeniería Mochis - Universidad Autónoma de Sinaloa**

Este repositorio contiene las prácticas, scripts y documentación generada durante el curso de Administración de Sistemas.

## 👤 Autor
* **Nombre:** Alberto Torres Chaparro
* **Grupo:** 3-01
* **Carrera:** Ingeniería de Software

---

## 📂 Contenido del Repositorio

### [Práctica 1: Entorno de Virtualización e Infraestructura Base]
Configuración de un laboratorio virtual con 3 nodos interconectados (Linux Server, Windows Server y Cliente Windows).

* **Tecnologías:** VirtualBox, Oracle Linux, Windows Server 2022.
* **Scripts:**
    * `check_status.sh`: Diagnóstico automatizado para servidores Linux.
    * `check_status.ps1`: Diagnóstico automatizado para servidores Windows.
* **Evidencias:** Pruebas de conectividad (Ping), configuración de hardware y Snapshots de respaldo.

### [Práctica 2: Automatización y Gestión del Servidor DHCP]
Implementación de soluciones de Infraestructura para el despliegue, configuración y monitoreo desatendido de servicios DHCP.

* **Tecnologías:** Kea DHCP Server (Oracle Linux), Microsoft DHCP Role (Windows Server), Bash, PowerShell.
* **Scripts Desarrollados:**
    * `servicio_kea.sh`: Script para Oracle Linux. Para la configuración automatizada de DHCP.
    * `servicio_dhcp.ps1`: Script para Windows Server. Para la configuración automatizada de DHCP.
* **Funcionalidades Clave:**
    * **Monitoreo en Tiempo Real:** Dashboard en consola que visualiza las concesiones de IP (Leases) al instante.
    * **Validación de Errores:** Control de fallos en servicios DNS y duplicidad de ámbitos.
