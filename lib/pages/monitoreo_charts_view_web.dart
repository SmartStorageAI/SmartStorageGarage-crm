// lib/pages/monitoreo_charts_view_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Vista web de monitoreo:
/// - Se conecta a Firebase Realtime Database (/sensores)
/// - Muestra tarjetas de Bodega 1 y Bodega 2 con los últimos valores
///   (distancia, estado, temperatura, humedad) en lugar de gráficas.
class MonitoreoChartsView extends StatelessWidget {
  MonitoreoChartsView({super.key}) {
    _registerViewFactory();
  }

  static const String _viewType = 'monitoreo-dashboard-view';
  static bool _registeredFactory = false;
  static bool _scriptInjected = false;

  void _registerViewFactory() {
    if (!kIsWeb) return;
    if (_registeredFactory) return;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%';

      container.setInnerHtml(
        _htmlContent,
        validator: html.NodeValidatorBuilder()
          ..allowHtml5()
          ..allowElement('div', attributes: ['style', 'id'])
          ..allowElement('span', attributes: ['style', 'id'])
          ..allowElement('p', attributes: ['style', 'id'])
          ..allowElement('h2', attributes: ['style'])
          ..allowElement('h3', attributes: ['style'])
          ..allowElement('strong', attributes: ['style']),
      );

      if (!_scriptInjected) {
        _injectScript();
        _scriptInjected = true;
      } else {
        // Ya existe el script: solo re-inicializamos el dashboard
        _reinitDashboard();
      }

      return container;
    });

    _registeredFactory = true;
  }

  // ---------- HTML del dashboard (2 columnas, tipo tarjetas) ----------

  static const String _htmlContent = '''
  <div style="
    width:100%;
    height:100%;
    box-sizing:border-box;
    display:flex;
    flex-direction:column;
    gap:24px;
  ">
    <div style="display:flex;flex-wrap:wrap;gap:24px;">

      <!-- BODEGA 1 -->
      <div style="
        flex:1 1 320px;
        background:#ede9fe;              /* violeta muy claro, pastel */
        border-radius:16px;
        padding:20px;
        color:#111827;                   /* texto oscuro para buen contraste */
        box-shadow:0 18px 40px rgba(167,139,250,0.7);
        box-sizing:border-box;
      ">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
          <div>
            <p style="margin:0;font-size:13px;opacity:0.85;">Bodega 1</p>
            <h3 style="margin:0;font-size:20px;font-weight:600;">Sensor de ocupación</h3>
          </div>
          <div id="b1-status-pill" style="
            padding:6px 12px;
            border-radius:999px;
            font-size:11px;
            font-weight:600;
            background:#22c55e33;
            color:#166534;
            text-transform:uppercase;
          ">
            <span id="b1-status">--</span>
          </div>
        </div>

        <div style="display:flex;gap:16px;align-items:stretch;margin-top:8px;">
          <div style="
            flex:1;
            background:#c4b5fd;          /* tarjeta interna morado pastel */
            border-radius:12px;
            padding:12px;
            box-sizing:border-box;
          ">
            <p style="margin:0;font-size:11px;opacity:0.85;">Distancia actual</p>
            <p id="b1-distance" style="margin:4px 0 0;font-size:30px;font-weight:700;">--</p>
            <p style="margin:2px 0 0;font-size:11px;opacity:0.8;">Umbral de alerta &lt; 20 cm</p>
          </div>

          <div style="
            flex:1;
            background:#a78bfa;          /* morado medio sólido */
            border-radius:12px;
            padding:12px;
            box-sizing:border-box;
            color:#f9fafb;
          ">
            <p style="margin:0;font-size:11px;opacity:0.9;">Alarma / buzzer</p>
            <p id="b1-alert" style="margin:6px 0 0;font-size:15px;font-weight:500;">--</p>
          </div>
        </div>

        <p id="b1-updated" style="margin:14px 0 0;font-size:11px;opacity:0.85;">
          Última actualización: --
        </p>
      </div>

      <!-- BODEGA 2 -->
      <div style="
        flex:1 1 320px;
        background:#ede9fe;
        border-radius:16px;
        padding:20px;
        color:#111827;
        box-shadow:0 18px 40px rgba(167,139,250,0.7);
        box-sizing:border-box;
      ">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
          <div>
            <p style="margin:0;font-size:13px;opacity:0.85;">Bodega 2</p>
            <h3 style="margin:0;font-size:20px;font-weight:600;">Ocupación, temperatura y humedad</h3>
          </div>
          <div id="b2-status-pill" style="
            padding:6px 12px;
            border-radius:999px;
            font-size:11px;
            font-weight:600;
            background:#22c55e33;
            color:#166534;
            text-transform:uppercase;
          ">
            <span id="b2-status">--</span>
          </div>
        </div>

        <div style="display:flex;flex-wrap:wrap;gap:12px;">

          <div style="
            flex:1 1 130px;
            background:#c4b5fd;
            border-radius:12px;
            padding:12px;
            box-sizing:border-box;
          ">
            <p style="margin:0;font-size:11px;opacity:0.85;">Distancia</p>
            <p id="b2-distance" style="margin:4px 0 0;font-size:24px;font-weight:700;">--</p>
            <p style="margin:2px 0 0;font-size:11px;opacity:0.8;">Sensor sónico</p>
          </div>

          <div style="
            flex:1 1 130px;
            background:#a78bfa;
            border-radius:12px;
            padding:12px;
            box-sizing:border-box;
            color:#f9fafb;
          ">
            <p style="margin:0;font-size:11px;opacity:0.9;">Temperatura</p>
            <p id="b2-temp" style="margin:4px 0 0;font-size:24px;font-weight:700;">--</p>
            <p style="margin:2px 0 0;font-size:11px;opacity:0.85;">DHT11 (°C)</p>
          </div>

          <div style="
            flex:1 1 130px;
            background:#a78bfa;
            border-radius:12px;
            padding:12px;
            box-sizing:border-box;
            color:#f9fafb;
          ">
            <p style="margin:0;font-size:11px;opacity:0.9;">Humedad</p>
            <p id="b2-hum" style="margin:4px 0 0;font-size:24px;font-weight:700;">--</p>
            <p style="margin:2px 0 0;font-size:11px;opacity:0.85;">DHT11 (%)</p>
          </div>
        </div>

        <p id="b2-updated" style="margin:14px 0 0;font-size:11px;opacity:0.85;">
          Última actualización: --
        </p>
      </div>
    </div>
  </div>
  ''';

  // ---------- Script JS: lee /sensores y actualiza las tarjetas ----------
  void _injectScript() {
    final existing = html.document.getElementById('monitoreo-dashboard-script');
    if (existing != null) return;

    final script = html.ScriptElement()
      ..id = 'monitoreo-dashboard-script'
      ..type = 'text/javascript'
      ..innerHtml = '''
        (function() {
          if (typeof firebase === 'undefined') {
            console.error('[Monitoreo] firebase no está definido. Revisa index.html.');
            return;
          }

          const DIST_THRESHOLD = 20; // igual que en el código de la ESP32
          const el = (id) => document.getElementById(id);

          const formatNumber = (v, suffix) => {
            const n = Number(v);
            if (isNaN(n)) return '--';
            return n.toFixed(1) + suffix;
          };

          const setStatus = (pill, statusEl, isOccupied) => {
            if (!pill || !statusEl) return;
            if (isOccupied) {
              pill.style.background = 'rgba(220,38,38,0.15)';
              pill.style.color = '#991b1b';
              statusEl.textContent = 'OCUPADA';
            } else {
              pill.style.background = 'rgba(22,163,74,0.15)';
              pill.style.color = '#166534';
              statusEl.textContent = 'LIBRE';
            }
          };

          const setAlert = (elAlert, isOccupied) => {
            if (!elAlert) return;
            if (isOccupied) {
              elAlert.textContent = 'Alarma activa (buzzer encendido)';
              elAlert.style.color = '#fecaca';
            } else {
              elAlert.textContent = 'Sin alerta (buzzer apagado)';
              elAlert.style.color = '#bbf7d0';
            }
          };

          // Mantener el último valor para poder re-pintar al volver a entrar
          let lastValue = null;

          const applySnapshotToDom = (val) => {
            if (!val) return;

            const b1 = val.bodega1 || {};
            const b2 = val.bodega2 || {};

            const dist1 = Number(b1.dist);
            const dist2 = Number(b2.dist);
            const temp2 = Number(b2.temp);
            const hum2  = Number(b2.hum);

            const b1Distance   = el('b1-distance');
            const b1Alert      = el('b1-alert');
            const b1Status     = el('b1-status');
            const b1StatusPill = el('b1-status-pill');
            const b1Updated    = el('b1-updated');

            const b2Distance   = el('b2-distance');
            const b2Temp       = el('b2-temp');
            const b2Hum        = el('b2-hum');
            const b2Status     = el('b2-status');
            const b2StatusPill = el('b2-status-pill');
            const b2Updated    = el('b2-updated');

            if (b1Distance) {
              b1Distance.textContent = formatNumber(dist1, ' cm');
            }
            if (b2Distance) {
              b2Distance.textContent = formatNumber(dist2, ' cm');
            }
            if (b2Temp) {
              b2Temp.textContent = formatNumber(temp2, ' °C');
            }
            if (b2Hum) {
              b2Hum.textContent = formatNumber(hum2, ' %');
            }

            const occ1 = !isNaN(dist1) && dist1 > 0 && dist1 < DIST_THRESHOLD;
            const occ2 = !isNaN(dist2) && dist2 > 0 && dist2 < DIST_THRESHOLD;

            setStatus(b1StatusPill, b1Status, occ1);
            setStatus(b2StatusPill, b2Status, occ2);
            setAlert(b1Alert, occ1);

            const nowStr = new Date().toLocaleTimeString();
            if (b1Updated) b1Updated.textContent = 'Última actualización: ' + nowStr;
            if (b2Updated) b2Updated.textContent = 'Última actualización: ' + nowStr;
          };

          function initDashboard() {
            const b1Status = el('b1-status');
            const b2Status = el('b2-status');

            // Si aún no existen los elementos, esperamos y reintentamos
            if (!b1Status || !b2Status) {
              console.warn('[Monitoreo] Esperando elementos del dashboard...');
              setTimeout(initDashboard, 250);
              return;
            }

            // Si ya tenemos un valor previo (por ejemplo, venimos de otra vista),
            // lo aplicamos inmediatamente a los nuevos elementos.
            if (lastValue) {
              applySnapshotToDom(lastValue);
            }
          }

          // Listener global (solo se registra una vez)
          const ref = firebase.database().ref('sensores');
          ref.on('value', snapshot => {
            lastValue = snapshot.val() || {};
            applySnapshotToDom(lastValue);
          });

          // Exponer función global para poder reinicializar desde Dart
          window.__monitoreoInitDashboard = initDashboard;

          // Primera inicialización
          initDashboard();
        })();
      ''';

    html.document.body?.append(script);
  }

  // Re-ejecutar initDashboard desde Dart cuando se vuelve a montar la vista
  void _reinitDashboard() {
    if (!kIsWeb) return;
    try {
      js_util.callMethod(html.window, '__monitoreoInitDashboard', const []);
    } catch (_) {
      // ignore: avoid_print
      print('[Monitoreo] No se pudo reinicializar el dashboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
