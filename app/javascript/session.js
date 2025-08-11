(function () {
    console.log("session.js loaded!!!");
    function hideModal(modalEl) {
      const Modal = window.bootstrap?.Modal;
      if (Modal?.getOrCreateInstance) {
        Modal.getOrCreateInstance(modalEl).hide();
        return;
      }
      // 폴백(전역 bootstrap 없는 경우)
      modalEl.classList.remove('show');
      modalEl.style.display = 'none';
      document.body.classList.remove('modal-open');
      document.body.style.removeProperty('paddingRight');
      document.querySelector('.modal-backdrop')?.remove();
    }
  
    function wire() {
      const modalEl = document.getElementById('sign_in_modal');
      if (!modalEl) return;
  
      const form = modalEl.querySelector('#login-form') || modalEl.querySelector('form');
      if (!form || form.__bound) return;
      form.__bound = true;
  
      // Rails UJS 경로
      form.addEventListener('ajax:success', (e) => {
        const [_data, _status, xhr] = e.detail || [];
        // 2xx 면 무조건 닫기
        if (xhr && xhr.status >= 200 && xhr.status < 300) {
          // alert('성공적으로 로그인했습니다!'); // 원하면 표시
          hideModal(modalEl);
          // window.location.reload(); // 필요 시
        }
      });
  
      form.addEventListener('ajax:error', (e) => {
        const [data, _status, _xhr] = e.detail || [];
        const msg = (data && data.errors && data.errors.join('\n')) || '이메일 또는 비밀번호가 올바르지 않습니다.';
        alert(msg);
      });
  
      // Turbo 경로 (혹시 turbo를 켜면 이 이벤트가 동작)
      form.addEventListener('turbo:submit-end', (e) => {
        if (e.detail?.success) {
          hideModal(modalEl);
          // window.location.reload();
        }
      });
    }
  
    document.addEventListener('turbo:load', wire);
    document.addEventListener('DOMContentLoaded', wire);
  })();
  